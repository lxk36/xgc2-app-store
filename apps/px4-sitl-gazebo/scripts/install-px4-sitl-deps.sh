#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" != "0" ]]; then
  echo "install-px4-sitl-deps.sh must run as root" >&2
  exit 1
fi

rosdistro="${ROS_DISTRO:-noetic}"

apt-get update
apt-get install -y --no-install-recommends \
  bc \
  ca-certificates \
  git \
  iputils-ping \
  libgazebo11-dev \
  netbase \
  python-is-python3 \
  python3-pip \
  wget \
  xmlstarlet \
  gazebo11 \
  ros-${rosdistro}-gazebo-ros \
  ros-${rosdistro}-mavros \
  ros-${rosdistro}-mavros-extras \
  ros-${rosdistro}-robot-state-publisher \
  ros-${rosdistro}-xacro

python3 -m pip install --no-cache-dir \
  empy \
  jinja2 \
  kconfiglib \
  netifaces \
  numpy \
  packaging \
  pyros-genmsg \
  pyyaml \
  toml

if [[ -x "/opt/ros/${rosdistro}/lib/mavros/install_geographiclib_datasets.sh" ]]; then
  /opt/ros/${rosdistro}/lib/mavros/install_geographiclib_datasets.sh || true
fi
