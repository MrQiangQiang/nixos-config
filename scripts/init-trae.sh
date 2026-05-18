#!/usr/bin/env bash

set -euo pipefail

CONTAINER_NAME="trae-env"
IMAGE="docker.io/library/ubuntu:24.04"

echo "=> [Host] Checking Distrobox container status..."
if ! distrobox list --no-color | grep -qw "$CONTAINER_NAME"; then
  echo "=> [Host] Container not found. Creating a clean Ubuntu environment.."
  distrobox create --name "$CONTAINER_NAME" --image "$IMAGE" --yes
fi

echo "=> [Host] Entering container to inject the automated setup script.."
distrobox enter "$CONTAINER_NAME" -- bash << 'EOF'
  set -euo pipefail
  export DEBIAN_FRONTEND=noninteractive

  echo "=> [Container] Synchronizing local API repositories..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq wget ca-certificates > /dev/null

  CURRENT_STATUS=$(dpkg-query -W -f='${Status}' trae 2>/dev/null || echo "not-installed")
  echo "=> [Container] Explicit Trae Status: [$CURRENT_STATUS]"

  if [ "$CURRENT_STATUS" != "install ok installed" ]; then
    echo "=> [Container] Target package not found. Downloading the latest Linux stable release from ByteDance CDN..."
    wget --no-check-certificate -q "https://cdn.trae.cn/releases/stable/linux/trae-cn-latest.deb" -O /tmp/trae.deb

    echo "=> [Container] Unpacking and automatically resolving graphical system dependencies..."
    sudo apt-get install -y -qq /tmp/trae.deb > /dev/null
    rm -f /tmp/trae.deb
  else
    echo "=> [Container] Trae is already installed via dpkg. Skipping download stage."
  fi

  echo "=> [Container] Injecting Wayland optimizations and disabling sandbox constraints..."
  if [ -f /usr/share/applications/trae.desktop ]; then
    sudo sed -i 's|^Exec=.*trae.*|Exec=/usr/bin/trae --no-sandbox --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --password-store=basic %U|g' /usr/share/applications/trae.desktop
  fi

  echo "=> [Container] Exporting graphical desktop entry to the Nixos host..."
  distrobox-export --app trae
EOF

echo "=============================================================="
echo "=> [Host] Congratulations! Trae IDE is now ready for your River desktop!"
echo "=> [Host] You can now search for 'Trae' directly in Rofi / Fuzzel to launch it."
echo "=============================================================="
