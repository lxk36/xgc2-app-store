#!/usr/bin/env bash
set -euo pipefail

source /opt/ros/noetic/setup.bash
test "${DISABLE_ROS1_EOL_WARNINGS:-}" = "1"
rosversion -d >/dev/null
gazebo --version >/dev/null
test -d "${PX4_AUTOPILOT_HOME:-/root/PX4-Autopilot}"
test -x "${PX4_AUTOPILOT_HOME:-/root/PX4-Autopilot}/build/px4_sitl_default/bin/px4"
