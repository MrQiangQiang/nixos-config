#!/usr/bin/env bash
set -eo pipefail

ENV_DIR="$HOME/.bashrc.d"
ENV_FILE="$ENV_DIR/trae-env.sh"

mkdir -p "$ENV_DIR"

cat << 'EOF' > "$ENV_FILE"
# === 动态感知组件: 实现同步宿主机 Wayland 与 DBus 环境 ===
if [ -z "${WAYLAND_DISPLAY}" ]; then
  export WAYLAND_DISPLAY="wayland-0"
fi
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
export BROWSER="distrobox-host-exec firefox"
EOF

echo "=> [Hook] Environment variables written to $ENV_FILE"
