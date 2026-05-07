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
| `ros-noetic-desktop-full` | `ghcr.io/lxk36/xgc2-app-store/ros-noetic-desktop-full` | Official OSRF ROS Noetic desktop-full image mirrored for amd64 deployments. |
| `ros-noetic-robot-focal` | `ghcr.io/lxk36/xgc2-app-store/ros-noetic-robot-focal` | Official ROS Noetic robot-focal image mirrored for amd64, arm/v7 and arm64 deployments. |

## Catalog

XGC can sync the static catalog from:

```text
https://raw.githubusercontent.com/lxk36/xgc2-app-store/master/catalog/index.yml
```

The catalog points to app files in this repository and GHCR images built by CI.

## Image Build

Only app definitions changed by a commit are built or mirrored. The detector
looks for changes under:

```text
apps/<app-key>/
```

An app without `apps/<app-key>/Dockerfile` is treated as an external-image app.
CI reads `upstreamImage` from `app.yml` and mirrors that image into the XGC app
registry tags. If the app declares multiple architectures, CI copies the full
manifest list so deployment hosts can pull the matching architecture.

Deleting an `apps/<app-key>/` directory is detected and reported by CI, but
registry tag deletion is intentionally not automated. Remove old image tags
manually after confirming no deployment still references them.

For pull requests, CI builds changed images without pushing. For `master`, CI
always pushes:

```text
ghcr.io/lxk36/xgc2-app-store/<app-key>:latest
ghcr.io/lxk36/xgc2-app-store/<app-key>:<version>
```

If domestic registry secrets are configured, CI also pushes the same image tags
to that registry:

```text
<XGC_CN_REGISTRY>/<XGC_CN_NAMESPACE>/<app-key>:latest
<XGC_CN_REGISTRY>/<XGC_CN_NAMESPACE>/<app-key>:<version>
```

The recommended first domestic target is an Aliyun ACR namespace dedicated to
XGC app images, for example:

```text
registry.cn-hangzhou.aliyuncs.com/xgc2-app-store
```

Keep this namespace public if deployment hosts should pull without `docker
login`. Keep it private only when every deployment host can be preconfigured
with registry credentials.

### Domestic Registry Secrets

Add these repository secrets under GitHub repository Settings -> Secrets and
variables -> Actions -> Repository secrets:

| Secret | Example | Purpose |
| --- | --- | --- |
| `XGC_CN_REGISTRY` | `registry.cn-hangzhou.aliyuncs.com` | Registry host. Do not include a namespace. |
| `XGC_CN_NAMESPACE` | `xgc2-app-store` | Registry namespace/project for XGC app images. |
| `XGC_CN_USERNAME` | `xgc2-ci` | Registry username or service account. |
| `XGC_CN_PASSWORD` | `***` | Registry password or access token. |

The workflow does not print these values. If any domestic registry setting is
missing, the GHCR push still works and the domestic push is skipped.

## Local Smoke

```bash
docker build -t xgc-ros1-runtime:local apps/xgc-ros1-runtime
docker run --rm xgc-ros1-runtime:local bash -lc \
  'source /opt/ros/noetic/setup.bash && rosversion -d && roscore --help >/dev/null'
```

For GUI/Gazebo usage, run through the app compose file or mount X11 manually.
