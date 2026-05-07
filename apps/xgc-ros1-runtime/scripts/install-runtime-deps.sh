#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" != "0" ]]; then
  echo "install-runtime-deps.sh must run as root" >&2
  exit 1
fi

rosdistro="${ROS_DISTRO:-noetic}"

apt-get update
apt-get install -y --no-install-recommends \
  bash-completion \
  bc \
  ffmpeg \
  git \
  iputils-ping \
  libgazebo11-dev \
  libssh2-1-dev \
  libzmqpp-dev \
  net-tools \
  netbase \
  nmap \
  python-is-python3 \
  python3-pip \
  rsync \
  sshpass \
  vim \
  wget \
  x11-utils \
  xdotool \
  xmlstarlet \
  gazebo11 \
  ros-${rosdistro}-camera-info-manager \
  ros-${rosdistro}-codec-image-transport \
  ros-${rosdistro}-gazebo-ros \
  ros-${rosdistro}-gazebo-ros-pkgs \
  ros-${rosdistro}-image-transport-plugins \
  ros-${rosdistro}-mavros \
  ros-${rosdistro}-mavros-extras \
  ros-${rosdistro}-plotjuggler-ros \
  ros-${rosdistro}-robot-state-publisher \
  ros-${rosdistro}-rviz \
  ros-${rosdistro}-vrpn-client-ros \
  ros-${rosdistro}-xacro

python3 -m pip install --no-cache-dir \
  netifaces \
  PyQt5

if [[ -x "/opt/ros/${rosdistro}/lib/mavros/install_geographiclib_datasets.sh" ]]; then
  /opt/ros/${rosdistro}/lib/mavros/install_geographiclib_datasets.sh || true
fi

echo "source /opt/ros/${rosdistro}/setup.bash" >/etc/profile.d/xgc-ros1.sh
