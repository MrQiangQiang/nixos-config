#!/usr/bin/env bash
set -euo pipefail

ENV_DIR="$HOME/.bashrc.d"
ENV_FILE="$ENV_DIR/trae-env.sh"

mkdir -p "$ENV_DIR"

cat << 'EOF' > "$ENV_FILE"
# === 注入宿主 Wayland 与 DBus 环境 ===
export WAYLAND_DISPLAY="$WAYLAND_DISPLAY"
export XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR"
export DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS"
export BROWSER="distrobox-host-exec firefox"
EOF

echo "=> [Hook] Environment variables written to $ENV_FILE"
