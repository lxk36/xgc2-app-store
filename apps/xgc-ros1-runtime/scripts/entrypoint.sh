#!/usr/bin/env bash
set -e

source /opt/ros/noetic/setup.bash
export DISABLE_ROS1_EOL_WARNINGS="${DISABLE_ROS1_EOL_WARNINGS:-1}"

if [[ -n "${ROS_IP:-}" ]]; then
  export ROS_IP
fi
if [[ -n "${ROS_HOSTNAME:-}" ]]; then
  export ROS_HOSTNAME
fi
export ROS_MASTER_URI="${ROS_MASTER_URI:-http://127.0.0.1:11311}"

exec "$@"
