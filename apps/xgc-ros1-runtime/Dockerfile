FROM osrf/ros:noetic-desktop-full

LABEL org.opencontainers.image.title="XGC ROS1 Runtime"
LABEL org.opencontainers.image.description="Lean ROS Noetic simulation runtime with MAVROS, VRPN, Gazebo Classic and core robot visualization dependencies."
LABEL org.opencontainers.image.source="https://github.com/lxk36/xgc2-app-store"

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=noetic
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY scripts/install-runtime-deps.sh /tmp/install-runtime-deps.sh
COPY scripts/entrypoint.sh /usr/local/bin/xgc-ros1-entrypoint
COPY scripts/healthcheck.sh /usr/local/bin/xgc-ros1-healthcheck

RUN chmod +x /tmp/install-runtime-deps.sh /usr/local/bin/xgc-ros1-entrypoint /usr/local/bin/xgc-ros1-healthcheck \
    && /tmp/install-runtime-deps.sh \
    && rm -f /tmp/install-runtime-deps.sh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home

ENTRYPOINT ["/usr/local/bin/xgc-ros1-entrypoint"]
CMD ["bash"]
