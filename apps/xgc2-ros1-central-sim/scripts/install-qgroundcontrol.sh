#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" != "0" ]]; then
  echo "install-qgroundcontrol.sh must run as root" >&2
  exit 1
fi

url="${QGC_APPIMAGE_URL:-}"
expected_sha256="${QGC_APPIMAGE_SHA256:-}"
download="$(mktemp --suffix=.AppImage)"
extract_dir="$(mktemp -d)"

cleanup() {
  rm -f "${download}"
  rm -rf "${extract_dir}"
}
trap cleanup EXIT

if [[ -z "${url}" || ! "${url}" =~ ^https:// ]]; then
  echo "QGC_APPIMAGE_URL must be an HTTPS URL" >&2
  exit 1
fi

if [[ ! "${expected_sha256}" =~ ^[0-9a-f]{64}$ ]]; then
  echo "QGC_APPIMAGE_SHA256 must contain a lowercase SHA-256 digest" >&2
  exit 1
fi

curl --fail --location --retry 5 --retry-delay 2 "${url}" -o "${download}"
echo "${expected_sha256}  ${download}" | sha256sum -c -
chmod +x "${download}"

cd "${extract_dir}"
"${download}" --appimage-extract >/dev/null
test -x squashfs-root/AppRun

rm -rf /opt/qgroundcontrol/appdir
install -d -m 0755 /opt/qgroundcontrol
mv squashfs-root /opt/qgroundcontrol/appdir
chmod -R a+rX /opt/qgroundcontrol/appdir
printf '%s\n' '4.4.4' >/opt/qgroundcontrol/VERSION
printf '%s\n' "${expected_sha256}" >/opt/qgroundcontrol/APPIMAGE_SHA256
