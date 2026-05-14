#!/usr/bin/env bash
set -eo pipefail

source /opt/ros/jazzy/setup.bash
command -v gz >/dev/null
ros2 pkg prefix ros_gz_bridge >/dev/null
