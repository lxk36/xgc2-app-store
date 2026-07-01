#!/usr/bin/env bash
set -euo pipefail

source /opt/ros/noetic/setup.bash
test "$(rosversion -d)" = "noetic"
command -v roscore >/dev/null
rviz --help >/dev/null
command -v gazebo >/dev/null
command -v git >/dev/null
command -v gdb >/dev/null
command -v glxinfo >/dev/null
test -x /opt/ros/noetic/lib/mavros/mavros_node
