# XGC2 App Store

Open app definitions and container images for XGC2.

This repository is intentionally small at the first stage. GitHub is used as the
app catalog server, and GitHub Container Registry is used for image hosting. No
public deployment server is required until XGC needs remote, unattended CD.

## Apps

| App | Image | Purpose |
| --- | --- | --- |
| `xgc-ros1-runtime` | `ghcr.io/lxk36/xgc2-app-store/xgc-ros1-runtime` | Curated ROS Noetic simulation toolkit for ROS1, MAVROS, VRPN, Gazebo Classic and core robot visualization. |
| `px4-sitl-gazebo` | `ghcr.io/lxk36/xgc2-app-store/px4-sitl-gazebo` | PX4 software-in-the-loop simulation toolkit for Gazebo Classic and ROS Noetic. |
| `ros-noetic-desktop-full` | `osrf/ros:noetic-desktop-full` | Official OSRF ROS Noetic desktop-full image, referenced directly without XGC2 image hosting. |

## Catalog

XGC can sync the static catalog from:

```text
https://raw.githubusercontent.com/lxk36/xgc2-app-store/master/catalog/index.yml
```

The catalog points to app files in this repository and GHCR images built by CI.

## Image Build

Only buildable apps changed by a commit are built. The detector looks for
changes under:

```text
apps/<app-key>/
```

An app without `apps/<app-key>/Dockerfile` is treated as an external-image app:
CI keeps it in the catalog but skips image build and push.

For pull requests, CI builds changed images without pushing. For `master`, CI
pushes:

```text
ghcr.io/lxk36/xgc2-app-store/<app-key>:latest
ghcr.io/lxk36/xgc2-app-store/<app-key>:<version>
```

## Local Smoke

```bash
docker build -t xgc-ros1-runtime:local apps/xgc-ros1-runtime
docker run --rm xgc-ros1-runtime:local bash -lc \
  'source /opt/ros/noetic/setup.bash && rosversion -d && roscore --help >/dev/null'
```

For GUI/Gazebo usage, run through the app compose file or mount X11 manually.
