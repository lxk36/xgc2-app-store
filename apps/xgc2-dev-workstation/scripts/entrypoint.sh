#!/usr/bin/env bash
set -euo pipefail

user="${XGC_USER:-xgc}"
uid="${USER_UID:-1000}"
gid="${USER_GID:-1000}"

if [[ "$(id -u)" == "0" ]]; then
  if ! getent group "${gid}" >/dev/null; then
    groupadd -g "${gid}" "${user}"
  fi
  if ! id "${user}" >/dev/null 2>&1; then
    useradd -m -u "${uid}" -g "${gid}" -s /bin/bash "${user}"
  else
    usermod -u "${uid}" -g "${gid}" "${user}" || true
  fi
  if [[ -S /var/run/docker.sock ]]; then
    docker_gid="$(stat -c '%g' /var/run/docker.sock)"
    if ! getent group "${docker_gid}" >/dev/null; then
      groupadd -g "${docker_gid}" docker-host
    fi
    usermod -aG "${docker_gid}" "${user}" || true
  fi
  echo "${user} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/xgc-user
  chmod 0440 /etc/sudoers.d/xgc-user
  mkdir -p /workspace
  chown -R "${uid}:${gid}" /workspace /home/"${user}" || true
  if ! grep -q "source /opt/ros/jazzy/setup.bash" /home/"${user}"/.bashrc; then
    echo "source /opt/ros/jazzy/setup.bash" >> /home/"${user}"/.bashrc
  fi
  exec gosu "${user}" "$@"
fi

exec "$@"
