#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

DEB_DIR="${HOME}/.local/share/trae-ide/pkgs"

echo "=> [Container] Synchronizing local API repositories..."
sudo apt-get update -qq || echo "[Warning] Slight jitter in package repository, ignoring..."

CURRENT_STATUS=$(dpkg-query -W -f='${Status}' trae 2>/dev/null || dpkg-query -W -f='${Status}' trae-cn 2>/dev/null || echo "not-installed")
INSTALLED_VER=$(dpkg-query -W -f='${Version}' trae 2>/dev/null || dpkg-query -W -f='${Version}' trae-cn 2>/dev/null || echo "0")

TRAE_DEB=$(ls -t "$DEB_DIR"/*.deb 2>/dev/null | head -n 1)

NEED_INSTALL=false

if [[ "$CURRENT_STATUS" != *"install ok installed"* ]]; then
  echo "=> [Container] Trae is not found yet."
  NEED_INSTALL=true
elif [ -n "$TRAE_DEB" ]; then
  DOWNLOAD_VER=$(dpkg-deb -f "TRAE_DEB" Version 2>/dev/null || echo "0")
  echo "=> [Container] Version Check: [Installed: $INSTALLED_VER] vs [Downloaded: $DOWNLOAD_VER]"
  if dpkg --compare-versions "$DOWNLOAD_VER" gt "$INSTALLED_VER"; then
    echo "=> [Container] Detected newer package version! Proceeding to upgrade..."
    NEED_INSTALL=true
  fi
fi

if [ "$NEED_INSTALL" = true ]; then
  if [ -z "$TRAE_DEB" ]; then
    echo "=> [Container Error] Missing installation package!"
    exit 1
  fi

  echo "=> [Container] Unpacking and resolving system graphical dependencies..."
  sudo apt-get install -y -qq "$TRAE_DEB" > /dev/null
  echo "=> [Container] Cleaning up transient package to keep environment stateless..."
  rm -f "$TRAE_DEB"
else
  echo "=> [Container] Trae is already up-to-date. Clearing stale transient debs..."
  rm -f "$DEB_DIR"/*.deb
fi

echo "=> [Container] Exporting graphical desktop entry with native Wayland flags..."
APP_NAME="trae"
if dpkg-query -W -f='${Status}' trae-cn | grep -q "install ok installed"; then
  APP_NAME="trae-cn"
fi

distrobox-export --app "$APP_NAME" \
  --extra-flags "--no-sandbox --enable-features=UseOzonePlatform,WaylandWindowDecorations 
--ozone-platform-hint=auto --enable-wayland-ime"

echo "=> [Container] Setup flow completed successfully!"
