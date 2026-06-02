#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" != "0" ]]; then
  echo "install-qt-5.15.2.sh must run as root" >&2
  exit 1
fi

qt_prefix="${XGC1_QT_PREFIX:-/opt/xgc1/toolchains/qt/5.15.2}"
qt_source_url="${QT_SOURCE_URL:-https://download.qt.io/archive/qt/5.15/5.15.2/single/qt-everywhere-src-5.15.2.tar.xz}"
qt_source_fallback_url="${QT_SOURCE_FALLBACK_URL:-}"
work_dir="$(mktemp -d)"

cleanup() {
  rm -rf "${work_dir}"
}
trap cleanup EXIT

apt-get update
apt-get install -y --no-install-recommends \
  bison \
  build-essential \
  clang \
  cmake \
  flex \
  gperf \
  libasound2-dev \
  libcap-dev \
  libdbus-1-dev \
  libegl1-mesa-dev \
  libevent-dev \
  libfontconfig1-dev \
  libglu1-mesa-dev \
  libgstreamer-plugins-bad1.0-dev \
  libgstreamer-plugins-base1.0-dev \
  libgstreamer-plugins-good1.0-dev \
  libgstreamer1.0-dev \
  libicu-dev \
  libnss3-dev \
  libpci-dev \
  libpulse-dev \
  libudev-dev \
  libx11-xcb-dev \
  libxcb-cursor-dev \
  libxcb-icccm4-dev \
  libxcb-image0-dev \
  libxcb-keysyms1-dev \
  libxcb-randr0-dev \
  libxcb-render-util0-dev \
  libxcb-shape0-dev \
  libxcb-shm0-dev \
  libxcb-sync-dev \
  libxcb-xfixes0-dev \
  libxcb-xinerama0-dev \
  libxcb-xkb-dev \
  libxcomposite-dev \
  libxcursor-dev \
  libxdamage-dev \
  libxi-dev \
  libxkbcommon-dev \
  libxkbcommon-x11-dev \
  libxrandr-dev \
  libxrender-dev \
  libxslt-dev \
  libxss-dev \
  libxtst-dev \
  nodejs \
  perl \
  pkg-config \
  python3 \
  ruby \
  tar \
  wget

mkdir -p "${qt_prefix}"
cd "${work_dir}"

if ! wget -q --show-progress --progress=bar:force:noscroll -O qt-everywhere-src-5.15.2.tar.xz "${qt_source_url}"; then
  if [[ -z "${qt_source_fallback_url}" ]]; then
    echo "failed to download Qt source from ${qt_source_url}" >&2
    exit 1
  fi
  wget -q --show-progress --progress=bar:force:noscroll -O qt-everywhere-src-5.15.2.tar.xz "${qt_source_fallback_url}"
fi

tar -xf qt-everywhere-src-5.15.2.tar.xz
cd qt-everywhere-src-5.15.2

./configure \
  -prefix "${qt_prefix}" \
  -opensource \
  -confirm-license \
  -release \
  -nomake examples \
  -nomake tests \
  -skip qtactiveqt \
  -skip qtandroidextras \
  -skip qtcanvas3d \
  -skip qtconnectivity \
  -skip qtdeclarative \
  -skip qtdoc \
  -skip qtgraphicaleffects \
  -skip qtimageformats \
  -skip qtlocation \
  -skip qtmacextras \
  -skip qtmultimedia \
  -skip qtnetworkauth \
  -skip qtquickcontrols \
  -skip qtquickcontrols2 \
  -skip qtquicktimeline \
  -skip qtremoteobjects \
  -skip qtscript \
  -skip qtscxml \
  -skip qtsensors \
  -skip qtserialbus \
  -skip qtserialport \
  -skip qtspeech \
  -skip qttools \
  -skip qttranslations \
  -skip qtwebchannel \
  -skip qtwebengine \
  -skip qtwebglplugin \
  -skip qtwebsockets \
  -skip qtwayland \
  -skip qtwinextras \
  -skip qtx11extras \
  -skip qtxmlpatterns \
  -skip qt3d \
  -skip qtcharts \
  -skip qtdatavis3d \
  -skip qtgamepad \
  -skip qtpurchasing \
  -skip qtvirtualkeyboard \
  -skip qtwebview

make -j"$(nproc)"
make install

find "${qt_prefix}" -type f -name '*.la' -delete
find "${qt_prefix}" -type f -name '*.debug' -delete

cat >/etc/profile.d/xgc1-qt.sh <<EOF
export XGC1_QT_PREFIX="${qt_prefix}"
export QT_PATH="${qt_prefix}"
export PATH="${qt_prefix}/bin:\${PATH}"
export LD_LIBRARY_PATH="${qt_prefix}/lib:\${LD_LIBRARY_PATH:-}"
export QT_PLUGIN_PATH="${qt_prefix}/plugins"
export CMAKE_PREFIX_PATH="/opt/ros/noetic:${qt_prefix}:\${CMAKE_PREFIX_PATH:-}"
EOF
