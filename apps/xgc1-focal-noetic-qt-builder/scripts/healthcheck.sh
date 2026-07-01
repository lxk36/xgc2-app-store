#!/usr/bin/env bash
set -euo pipefail

qt_prefix="${XGC1_QT_PREFIX:-/opt/xgc1/toolchains/qt/5.15.2}"
export PATH="${qt_prefix}/bin:${PATH}"
export LD_LIBRARY_PATH="${qt_prefix}/lib:${LD_LIBRARY_PATH:-}"
export QT_PLUGIN_PATH="${qt_prefix}/plugins"
export CMAKE_PREFIX_PATH="/opt/ros/noetic:${qt_prefix}:${CMAKE_PREFIX_PATH:-}"

source /opt/ros/noetic/setup.bash
test "$(rosversion -d)" = "noetic"
test "${DISABLE_ROS1_EOL_WARNINGS:-}" = "1"
test "$(qmake -query QT_VERSION)" = "5.15.2"
test -f "${qt_prefix}/lib/libQt5Widgets.so.5"
test -f "${qt_prefix}/plugins/platforms/libqxcb.so"
pkg-config --modversion Qt5Widgets | grep -qx '5\.15\.2'

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

cat >"${tmp_dir}/CMakeLists.txt" <<'EOF'
cmake_minimum_required(VERSION 3.16)
project(qt_healthcheck LANGUAGES CXX)
find_package(Qt5 5.15.2 REQUIRED COMPONENTS Widgets Xml Svg Network)
add_executable(qt_healthcheck main.cpp)
target_link_libraries(qt_healthcheck PRIVATE Qt5::Widgets Qt5::Xml Qt5::Svg Qt5::Network)
EOF
cat >"${tmp_dir}/main.cpp" <<'EOF'
#include <QApplication>
#include <QSvgRenderer>
#include <QDomDocument>
#include <QTcpSocket>

int main(int argc, char **argv) {
  QApplication app(argc, argv);
  QSvgRenderer renderer;
  QDomDocument document;
  QTcpSocket socket;
  return renderer.isValid() || document.isNull() || socket.isOpen() ? 0 : 0;
}
EOF

cmake -S "${tmp_dir}" -B "${tmp_dir}/build" >/dev/null
cmake --build "${tmp_dir}/build" >/dev/null
