FROM osrf/ros:noetic-desktop-full

LABEL org.opencontainers.image.title="PX4 SITL Gazebo"
LABEL org.opencontainers.image.description="PX4 software-in-the-loop simulation toolkit for Gazebo Classic and ROS Noetic."
LABEL org.opencontainers.image.source="https://github.com/lxk36/xgc2-app-store"

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=noetic
ENV PX4_SITL_HOME=/opt/px4_sitl_ws/src/px4_sitl
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG PX4_SITL_REPO=https://gitee.com/bhswift/px4_sitl.git
ARG PX4_SITL_REF=master

COPY scripts/install-px4-sitl-deps.sh /tmp/install-px4-sitl-deps.sh
COPY scripts/entrypoint.sh /usr/local/bin/px4-sitl-entrypoint
COPY scripts/healthcheck.sh /usr/local/bin/px4-sitl-healthcheck

RUN chmod +x /tmp/install-px4-sitl-deps.sh /usr/local/bin/px4-sitl-entrypoint /usr/local/bin/px4-sitl-healthcheck \
    && /tmp/install-px4-sitl-deps.sh \
    && mkdir -p /opt/px4_sitl_ws/src \
    && git clone --depth 1 --branch "${PX4_SITL_REF}" "${PX4_SITL_REPO}" "${PX4_SITL_HOME}" \
    && rm -f /tmp/install-px4-sitl-deps.sh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/px4_sitl_ws

ENTRYPOINT ["/usr/local/bin/px4-sitl-entrypoint"]
CMD ["bash"]
