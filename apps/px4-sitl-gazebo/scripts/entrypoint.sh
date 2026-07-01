#!/usr/bin/env bash
set -e

if [[ -f /opt/ros/noetic/setup.bash ]]; then
  source /opt/ros/noetic/setup.bash
fi
export DISABLE_ROS1_EOL_WARNINGS="${DISABLE_ROS1_EOL_WARNINGS:-1}"

export PX4_AUTOPILOT_HOME="${PX4_AUTOPILOT_HOME:-/root/PX4-Autopilot}"
export PX4_SITL_HOME="${PX4_SITL_HOME:-${PX4_AUTOPILOT_HOME}}"

cd "${PX4_AUTOPILOT_HOME}"

exec "$@"
