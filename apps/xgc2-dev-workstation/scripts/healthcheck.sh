#!/usr/bin/env bash
set -euo pipefail

source /opt/ros/jazzy/setup.bash
test "${ROS_DISTRO}" = "jazzy"
command -v ros2 >/dev/null
ros2 pkg prefix rclcpp >/dev/null
command -v cmake >/dev/null
command -v qmake6 >/dev/null
command -v docker >/dev/null
