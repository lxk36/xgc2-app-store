#!/usr/bin/env bash
set -e

source /opt/ros/noetic/setup.bash

if [[ -n "${ROS_IP:-}" ]]; then
  export ROS_IP
fi
if [[ -n "${ROS_HOSTNAME:-}" ]]; then
  export ROS_HOSTNAME
fi
export ROS_MASTER_URI="${ROS_MASTER_URI:-http://127.0.0.1:11311}"

exec "$@"
