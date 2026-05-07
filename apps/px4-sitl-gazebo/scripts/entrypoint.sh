#!/usr/bin/env bash
set -e

if [[ -f /opt/ros/noetic/setup.bash ]]; then
  source /opt/ros/noetic/setup.bash
fi

export PX4_AUTOPILOT_HOME="${PX4_AUTOPILOT_HOME:-/root/PX4-Autopilot}"
export PX4_SITL_HOME="${PX4_SITL_HOME:-${PX4_AUTOPILOT_HOME}}"
export PX4_SIM_SPEED_FACTOR="${PX4_SIM_SPEED_FACTOR:-1}"

cd "${PX4_AUTOPILOT_HOME}"

exec "$@"
