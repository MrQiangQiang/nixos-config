{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Pack the setup script into a standard Nix user application
  init-trae-script = pkgs.writeShellApplication {
    name = "init-trae";
    
    # Solidify host dependencies to ensure commands are found regardless of Shell PATH
    runtimeInputs = [ pkgs.distrobox ];

    text = ''
      # Enable strict error checking (writeShellApplication includes some env optimizations by default)
      set -euo pipefail
      
      CONTAINER_NAME="trae-env"
      IMAGE="ubuntu:24.04"

      echo "=> [Host] Checking Distrobox container status..."
      if ! distrobox list --no-color | grep -qw "$CONTAINER_NAME"; then
        echo "=> [Host] Container not found. Creating a clean Ubuntu environment.."
        distrobox create --name "$CONTAINER_NAME" --image "$IMAGE" --yes
      fi  
      
      echo "=> [Host] Entering container to inject the automated setup script.."
      # Standard << 'EOF' feeds the internal logic to the container's bash
      distrobox enter "$CONTAINER_NAME" --bash << 'EOF'
        set -euo pipefail
        export DEBIAN_FRONTEND=noninteractive
        
        echo "=> [Container] Synchronizing local API repositories..."
        sudo apt-get update -qq
        sudo apt-get install -y -qq wget ca-certificates > /dev/null
        
        echo "=> [Container] Verifying Trae IDE installation status via dpkg.."
        if ! dpkg-query -W -f=''${Status} trae 2>/dev/null | grep -q "install ok installed"; then
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
          mkdir -p "$HOME/.local/share/applications"
          cp /usr/share/applications/trae.desktop "$HOME/.local/share/applications/"

          # Modern Wayland Best Practices for Electron apps:
          # --no-sandbox: Fixes Electron crashes inside unprivileged user namespaces on newer kernels
          # --ozone-platform-hint=auto: Enables native Wayland rendering (prevents XWayland blurriness)
          # --enable-features=WaylandWindowDecorations: Ensures proper window scaling and borders
          # --password-store=basic: Prevents freezing by avoiding missing Gnome keyring loops in containers
          sed -i 's|Exec=/usr/bin/trae|Exec=/usr/bin/trae --no-sandbox --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --password-store=basic|g' "$HOME/.local/share/applications/trae.desktop"
        fi

        echo "=> [Container] Exporting graphical desktop entry to the Nixos host..."
EOF
# CRITICAL: This EOF marker must be completely flush-left (no spaces/tabs) for shellcheck to compile!

      echo "=============================================================="
      echo "=> [Host] Congratulations! Trae IDE is now ready for your River desktop!"
      echo "=> [Host] You can now search for 'Trae' directly in Rofi / Fuzzel to launch it." 
      echo "=============================================================="               
    '';
  };
in
{
  programs.distrobox.enable = true;
  
  home.packages = [
    init-trae-script
  ];
}
