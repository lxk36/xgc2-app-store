#!/usr/bin/env bash
set -euo pipefail

source /opt/ros/noetic/setup.bash
rosversion -d >/dev/null
gazebo --version >/dev/null
test -d "${PX4_SITL_HOME:-/opt/px4_sitl_ws/src/px4_sitl}"
