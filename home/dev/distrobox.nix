{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.distrobox.enable = true;

  home.file."distrobox-init-ubuntu.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      
      CONTAINER_NAME="ubuntu"
      IMAGE="ubuntu:26.04"
      TRAE_DEB_RUL="https://cdn.trae.cn/releases/stable/linux/trae-cn-latest.deb"
      TRAE_START_SCRIPT="$HOME/start_trae.sh"

      # ---1. Container creation (idempotent) ---
      if distrobox list --no-color 2>/dev/null | grep -qw "$CONTAINER_NAME"; then
        echo "Container '$CONTAINER_NAME' already exists. Skipping creation."
      else
        echo "Creating container '$CONTAINER_NAME'..."
        distrobox create --name "$CONTAINER_NAME" --image "$IMAGE" --yes
      fi
    
      dexec() { distrobox enter "$CONTAINER_NAME" -- "$@"; }

      # ---2. Required libraries (install only missing ones) ---
      echo "Checking required libraries"
      REQUIRED_PKGS="libnss3 libatk1.0-0 libatk-bridge2.0-0 libcpus2 libdrm2
libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1
libpango-1.0-0 libasound2 libxshmfence1"
      MISSING = ""
      for pkg in $REQUIRED_PKGS; do
        if ! dexec dpkg -s "$pkg" 2>/dev/null | grep -q "install ok installed";
then
          MISSING="$MISSING $PKG"
        fi
      done
      if [ -n "$MISSING" ]; then
        echo "Installing missing packages": $MISSING"
        dexec sudo apt update -qq
        dexec sudo apt install -y -qq $MISSING
      else
        echo "All required librarues are already installed."
      fi

      # ---3. Trae IDE (version-aware idempotent install) ---
      echo "Checking Trae IDE..."
      if dexec dpkg -l trae 2>/dev/null | grep -q '^ii'; then
        echo "Trae IDE is already installed. Skipping download."
      else
        echo "Downloading Trae IDE..."
        dexec wget -q "$TRAE_DEB_URL" -o /tmp/trae.deb
        echo "Installing Trae IDE..."
        dexec sudo apt install -y -qq /tmp/trae/deb
        echo "Trae IDE installation completed."
      fi

      # ---4. Launcher script (idempotent) ---
      if dexec test -f "$TRAE_START_SCRIPT"; then
        echo "Launcher script already exists."
      else
        echo "Creating launcher script..."
        dexec bash -c "cat > $TRAE_START_SCRIPT << 'EOF'
#!/bin/bash
trae --no-sandbox --password-store=basic
EFO"
        dexec chmod +x "$TRAE_START_SCRIPT"
      fi

      echo ""
      echo "Initialization complete."
      echo "  Enter container: distrobox enter $CONTAINER_NAME"
      echo "  Start Trae: start_trae.sh"

    '';
  };
}
