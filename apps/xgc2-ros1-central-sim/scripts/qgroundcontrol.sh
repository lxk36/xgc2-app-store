#!/usr/bin/env bash
set -euo pipefail

appdir=/opt/qgroundcontrol/appdir
test -x "${appdir}/AppRun"

runtime_dir="${XDG_RUNTIME_DIR:-/tmp/xgc2-qgc-runtime-$(id -u)}"
install -d -m 0700 "${runtime_dir}"

export XDG_RUNTIME_DIR="${runtime_dir}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/var/lib/xgc2/qgroundcontrol/config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/var/lib/xgc2/qgroundcontrol/cache}"
export QT_X11_NO_MITSHM="${QT_X11_NO_MITSHM:-1}"
export QTWEBENGINE_DISABLE_SANDBOX="${QTWEBENGINE_DISABLE_SANDBOX:-1}"
export NO_AT_BRIDGE="${NO_AT_BRIDGE:-1}"

mkdir -p "${XDG_CONFIG_HOME}" "${XDG_CACHE_HOME}"

if [[ "${QGC_FORCE_SOFTWARE_OPENGL:-0}" == "1" ]]; then
  export LIBGL_ALWAYS_SOFTWARE=1
  export QT_QUICK_BACKEND=software
fi

cd "${appdir}"
exec ./AppRun "$@"
