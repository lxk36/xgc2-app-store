#!/usr/bin/env bash
set -euo pipefail

source /opt/ros/jazzy/setup.bash
command -v MicroXRCEAgent >/dev/null
test -d "${PX4_AUTOPILOT_HOME:-/opt/PX4-Autopilot}"
test -x /opt/qgroundcontrol/QGroundControl.AppImage
