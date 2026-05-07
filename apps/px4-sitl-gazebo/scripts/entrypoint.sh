#!/usr/bin/env bash
set -e

if [[ -f /opt/ros/noetic/setup.bash ]]; then
  source /opt/ros/noetic/setup.bash
fi

export PX4_SITL_HOME="${PX4_SITL_HOME:-/opt/px4_sitl_ws/src/px4_sitl}"
export PX4_SIM_SPEED_FACTOR="${PX4_SIM_SPEED_FACTOR:-1}"

exec "$@"
