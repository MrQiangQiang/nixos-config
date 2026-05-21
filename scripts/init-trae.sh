#!/usr/bin/env bash
set -euo pipefail

http_proxy="${http_proxy:-}"
https_proxy="${https_proxy:-}"
all_proxy="${all_proxy:-}"
no_proxy="${no_proxy:-}"

CONTAINER_NAME="trae-env"
IMAGE="docker.io/library/ubuntu:24.04"
SCRIPTS_HOST_DIR="${HOME}/nixos-config/scripts"
SCRIPTS_CONTAINER_DIR="/opt/init-scripts"
REAL_SETUP_SCRIPT="${SCRIPTS_HOST_DIR}/trae-container-setup.sh"

DEB_STORAGE="${HOME}/.local/share/trae-ide/pkgs"
mkdir -p "$DEB_STORAGE"

echo "=> [Host] Checking Distrobox container status..."
if ! distrobox list --no-color 2>/dev/null | grep -qw "$CONTAINER_NAME"; then
  echo "=> [Host] Container not found. Creating a clean Ubuntu environment.."
  distrobox create --name "$CONTAINER_NAME" --image "$IMAGE" --yes \
    --volume "${SCRIPTS_HOST_DIR}:${SCRIPTS_CONTAINER_DIR}:ro" \
    --additional-flags "--env WAYLAND_DISPLAY=$WAYLAND_DISPLAY --env 
XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR --env DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS" \
    --init-hooks "bash ${SCRIPTS_CONTAINER_DIR}/init-trae-bashrc-d.sh && bash $
{SCRIPTS_CONTAINER_DIR}/init-trae-hook-env.sh"
fi

shopt -s nullglob
storage_debs=("$DEB_STORAGE"/*.deb)
shopt -u nullglob

if [ ${#storage_debs[@]} -eq 0 ]; then
  DOWNLOAD_DIR=$(xdg-user-dir DOWNLOAD 2>/dev/null || echo "$HOME/Downloads")

  shopt -s nullglob
  downloaded_debs=("$DOWNLOAD_DIR"/*[Tt]rae*.deb)
  shopt -u nullglob

  if [ ${#downloaded_debs[@]} -gt 0 ]; then
    LATEST_DEB="${downloaded_debs[0]}"
    echo "=> [Host] Discovered fresh package in downloads: $(basename "$LATEST_DEB")"
    echo "=> [Host] Automatically relocating it to configuration storage..."
    mv "$LATEST_DEB" "$DEB_STORAGE"
  else
    echo "==============================================================="
    echo "=> [Host] Trae IDE local Package Missing!"
    echo "=> Bypassing CDN restrictions: Redirecting to official browser gateway."
    echo "==============================================================="
    xdg-open "https://www.trae.cn/ide/download" || true
    echo -e "\n Please let your browser download the '.deb' file normally."
    echo "Once download completes, simply re-run this script to continue!"
    exit 0
  fi
fi

if [ ! -f "$REAL_SETUP_SCRIPT" ]; then
  echo "=> [Host Error] Setup script not found at: $REAL_SETUP_SCRIPT."
  exit 1
fi

echo "=> [Host] Entering container to inject the automated setup script.."
EXIT_CODE=0

#http_proxy="{$http_proxy:-}" \
#https_proxy="{$https_proxy:-}" \
#all_proxy="{$all_proxy:-}" \
#no_proxy="{$no_proxy:-}" \
#WAYLAND_DISPLAY="{$WAYLAND_DISPLAY}" \
#XDG_RUNTIME_DIR="{$XDG_RUNTIME_DIR}" \
#DBUS_SESSION_BUS_ADDRESS="{$DBUS_SESSION_BUS_ADDRESS}" \
distrobox enter "$CONTAINER_NAME" \
  -- bash "$REAL_SETUP_SCRIPT" || EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "================================================================="
  echo "=> [Host] Congratulations! Trae IDE is now ready for your River desktop!"
  echo "================================================================="
else
  echo "================================================================="
  echo "=> [Host] Container setup script exited with error code: $EXIT_CODE"
  echo "================================================================="
  exit "$EXIT_CODE"
fi
