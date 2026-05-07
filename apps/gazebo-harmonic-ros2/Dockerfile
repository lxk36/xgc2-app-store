# syntax=docker/dockerfile:1.7
FROM osrf/ros:jazzy-desktop-full

LABEL org.opencontainers.image.title="Gazebo Harmonic ROS2 Bridge"
LABEL org.opencontainers.image.description="Gazebo Harmonic with ROS 2 Jazzy integration for simulation workloads."
LABEL org.opencontainers.image.source="https://github.com/lxk36/xgc2-app-store"

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=jazzy
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY scripts/entrypoint.sh /usr/local/bin/xgc-entrypoint
COPY scripts/healthcheck.sh /usr/local/bin/gazebo-harmonic-healthcheck

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      gosu \
      iputils-ping \
      ros-jazzy-ros-gz \
      sudo \
    && chmod +x /usr/local/bin/xgc-entrypoint /usr/local/bin/gazebo-harmonic-healthcheck \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/xgc-entrypoint"]
CMD ["bash"]
