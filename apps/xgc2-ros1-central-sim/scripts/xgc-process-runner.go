package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"strconv"
	"syscall"
	"time"
)

const (
	maxFileBytes = int64(5 * 1024 * 1024)
	maxReadBytes = int64(256 * 1024)
)

type logMetadata struct {
	CurrentBase  int64 `json:"currentBase"`
	CurrentSize  int64 `json:"currentSize"`
	PreviousBase int64 `json:"previousBase"`
	PreviousSize int64 `json:"previousSize"`
}

type rotatingStream struct {
	current  string
	previous string
	metadata string
	meta     logMetadata
	file     *os.File
}

func openRotatingStream(root, name string) (*rotatingStream, error) {
	if err := os.MkdirAll(root, 0o750); err != nil {
		return nil, err
	}
	stream := &rotatingStream{
		current: filepath.Join(root, name+".log"), previous: filepath.Join(root, name+".log.1"),
		metadata: filepath.Join(root, name+".meta.json"),
	}
	if data, err := os.ReadFile(stream.metadata); err == nil {
		if err := json.Unmarshal(data, &stream.meta); err != nil {
			return nil, err
		}
	} else if !errors.Is(err, os.ErrNotExist) {
		return nil, err
	} else {
		if info, statErr := os.Stat(stream.previous); statErr == nil {
			stream.meta.PreviousSize = info.Size()
			stream.meta.CurrentBase = info.Size()
		}
		if info, statErr := os.Stat(stream.current); statErr == nil {
			stream.meta.CurrentSize = info.Size()
		}
	}
	file, err := os.OpenFile(stream.current, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0o640)
	if err != nil {
		return nil, err
	}
	stream.file = file
	if info, statErr := file.Stat(); statErr == nil {
		stream.meta.CurrentSize = info.Size()
	}
	if err := stream.persist(); err != nil {
		_ = file.Close()
		return nil, err
	}
	return stream, nil
}

func (s *rotatingStream) Write(data []byte) (int, error) {
	written := 0
	for len(data) > 0 {
		if s.meta.CurrentSize >= maxFileBytes {
			if err := s.rotate(); err != nil {
				return written, err
			}
		}
		available := maxFileBytes - s.meta.CurrentSize
		part := data
		if int64(len(part)) > available {
			part = part[:available]
		}
		n, err := s.file.Write(part)
		written += n
		s.meta.CurrentSize += int64(n)
		if persistErr := s.persist(); err == nil {
			err = persistErr
		}
		if err != nil {
			return written, err
		}
		data = data[n:]
	}
	return written, nil
}

func (s *rotatingStream) rotate() error {
	if err := s.file.Close(); err != nil {
		return err
	}
	if err := os.Remove(s.previous); err != nil && !errors.Is(err, os.ErrNotExist) {
		return err
	}
	if err := os.Rename(s.current, s.previous); err != nil && !errors.Is(err, os.ErrNotExist) {
		return err
	}
	s.meta.PreviousBase = s.meta.CurrentBase
	s.meta.PreviousSize = s.meta.CurrentSize
	s.meta.CurrentBase += s.meta.CurrentSize
	s.meta.CurrentSize = 0
	file, err := os.OpenFile(s.current, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0o640)
	if err != nil {
		return err
	}
	s.file = file
	return s.persist()
}

func (s *rotatingStream) persist() error {
	data, err := json.Marshal(s.meta)
	if err != nil {
		return err
	}
	temporary := fmt.Sprintf("%s.tmp.%d", s.metadata, os.Getpid())
	if err := os.WriteFile(temporary, append(data, '\n'), 0o640); err != nil {
		return err
	}
	return os.Rename(temporary, s.metadata)
}

func (s *rotatingStream) Close() error { return s.file.Close() }

func run(logDir string, argv []string) int {
	if len(argv) == 0 {
		fmt.Fprintln(os.Stderr, "xgc-process-runner: executable argv is required")
		return 2
	}
	stdout, err := openRotatingStream(logDir, "stdout")
	if err != nil {
		fmt.Fprintln(os.Stderr, "xgc-process-runner:", err)
		return 2
	}
	stderr, err := openRotatingStream(logDir, "stderr")
	if err != nil {
		_ = stdout.Close()
		fmt.Fprintln(os.Stderr, "xgc-process-runner:", err)
		return 2
	}
	command := exec.Command(argv[0], argv[1:]...)
	command.Stdin = nil
	command.Stdout = stdout
	command.Stderr = stderr
	if err := command.Start(); err != nil {
		_ = stdout.Close()
		_ = stderr.Close()
		fmt.Fprintln(os.Stderr, "xgc-process-runner:", err)
		return 2
	}
	// TERM/KILL is sent to the whole process group. Keep this runner alive on
	// TERM so it can drain the child's pipes; KILL still ends the full group.
	term := make(chan os.Signal, 2)
	signal.Notify(term, syscall.SIGTERM, syscall.SIGINT)
	defer signal.Stop(term)
	go func() {
		for range term { /* group signal already reached the child */
		}
	}()
	waitErr := command.Wait()
	_ = stdout.Close()
	_ = stderr.Close()
	code := 0
	if waitErr != nil {
		code = 1
		if command.ProcessState != nil {
			if exited := command.ProcessState.ExitCode(); exited >= 0 {
				code = exited
			}
		}
	}
	return code
}

type exitMetadata struct {
	ExitCode            int   `json:"exitCode"`
	FinishedAtUnixMilli int64 `json:"finishedAtUnixMilli"`
}

func persistExit(path string, code int) error {
	if path == "" {
		return errors.New("exit file is required")
	}
	data, err := json.Marshal(exitMetadata{ExitCode: code, FinishedAtUnixMilli: time.Now().UnixMilli()})
	if err != nil {
		return err
	}
	temporary := fmt.Sprintf("%s.tmp.%d", path, os.Getpid())
	if err := os.WriteFile(temporary, append(data, '\n'), 0o600); err != nil {
		return err
	}
	return os.Rename(temporary, path)
}

type logChunk struct {
	Offset     int64  `json:"offset"`
	NextOffset int64  `json:"nextOffset"`
	Truncated  bool   `json:"truncated"`
	Data       []byte `json:"data"`
}

func readLog(logDir, streamName string, offset, limit int64) error {
	if streamName != "stdout" && streamName != "stderr" {
		return errors.New("stream must be stdout or stderr")
	}
	if offset < 0 || limit < 1 || limit > maxReadBytes {
		return errors.New("invalid offset or limit")
	}
	current := filepath.Join(logDir, streamName+".log")
	previous := filepath.Join(logDir, streamName+".log.1")
	metadataPath := filepath.Join(logDir, streamName+".meta.json")
	var meta logMetadata
	data, err := os.ReadFile(metadataPath)
	if err == nil {
		if err := json.Unmarshal(data, &meta); err != nil {
			return err
		}
	} else if !errors.Is(err, os.ErrNotExist) {
		return err
	} else {
		if info, statErr := os.Stat(previous); statErr == nil {
			meta.PreviousSize = info.Size()
			meta.CurrentBase = info.Size()
		}
		if info, statErr := os.Stat(current); statErr == nil {
			meta.CurrentSize = info.Size()
		}
	}
	earliest := meta.CurrentBase
	if meta.PreviousSize > 0 {
		earliest = meta.PreviousBase
	}
	requested := offset
	truncated := offset < earliest
	if truncated {
		offset = earliest
	}
	result := make([]byte, 0, limit)
	appendFile := func(path string, base, size int64) error {
		if int64(len(result)) >= limit || size <= 0 || offset >= base+size {
			return nil
		}
		file, openErr := os.Open(path)
		if errors.Is(openErr, os.ErrNotExist) {
			return nil
		}
		if openErr != nil {
			return openErr
		}
		defer file.Close()
		start := offset
		if start < base {
			start = base
		}
		if _, seekErr := file.Seek(start-base, io.SeekStart); seekErr != nil {
			return seekErr
		}
		readLimit := min(limit-int64(len(result)), base+size-start)
		part, readErr := io.ReadAll(io.LimitReader(file, readLimit))
		if readErr != nil {
			return readErr
		}
		result = append(result, part...)
		offset = start + int64(len(part))
		return nil
	}
	if err := appendFile(previous, meta.PreviousBase, meta.PreviousSize); err != nil {
		return err
	}
	if err := appendFile(current, meta.CurrentBase, meta.CurrentSize); err != nil {
		return err
	}
	responseOffset := requested
	if truncated {
		responseOffset = earliest
	}
	return json.NewEncoder(os.Stdout).Encode(logChunk{Offset: responseOffset, NextOffset: offset, Truncated: truncated, Data: result})
}

func parse(argv []string) (map[string]string, []string, error) {
	values := map[string]string{}
	for index := 0; index < len(argv); {
		if argv[index] == "--" {
			return values, argv[index+1:], nil
		}
		if index+1 >= len(argv) || len(argv[index]) < 3 || argv[index][:2] != "--" {
			return nil, nil, fmt.Errorf("invalid argument %q", argv[index])
		}
		values[argv[index][2:]] = argv[index+1]
		index += 2
	}
	return values, nil, nil
}

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "xgc-process-runner: mode is required")
		os.Exit(2)
	}
	values, command, err := parse(os.Args[2:])
	if err != nil {
		fmt.Fprintln(os.Stderr, "xgc-process-runner:", err)
		os.Exit(2)
	}
	switch os.Args[1] {
	case "run":
		code := run(values["log-dir"], command)
		if persistErr := persistExit(values["exit-file"], code); persistErr != nil {
			fmt.Fprintln(os.Stderr, "xgc-process-runner: persist exit:", persistErr)
			code = 2
		}
		os.Exit(code)
	case "read":
		offset, offsetErr := strconv.ParseInt(values["offset"], 10, 64)
		limit, limitErr := strconv.ParseInt(values["limit"], 10, 64)
		if offsetErr != nil || limitErr != nil {
			err = errors.New("offset and limit must be integers")
		} else {
			err = readLog(values["log-dir"], values["stream"], offset, limit)
		}
	default:
		err = fmt.Errorf("unsupported mode %q", os.Args[1])
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, "xgc-process-runner:", err)
		os.Exit(2)
	}
}
