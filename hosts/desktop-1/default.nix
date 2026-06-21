{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  keys = import ../../secrets/keys.nix;
in
{
  imports = [
    inputs.disko.nixosModules.disko
    ./disk-config.nix
    ../../modules/desktop.nix
    ../../modules/proxy.nix
    ../../modules/im.nix
    ../../modules/tailscale.nix
    ../../modules/git-annex.nix
    ./hardware-configuration.nix
  ];

  system.stateVersion = "26.11";

  # ── Kernel ─────────────────────────────────────────────────

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "pcie_aspm=off"
    "amd_pstate=active"
    "modprobe.blacklist=nouveau"
    "nouveau.modeset=0"
  ];

  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.extraModulePackages = [ config.boot.kernelPackages.nvidiaPackages.stable.open ];

  hardware.cpu.amd.updateMicrocode = true;

  zramSwap.enable = true;

  # ── GPU: PRIME Offload ─────────────────────────────────────

  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      amdgpuBusId = "PCI:115@0:0:0";
      nvidiaBusId = "PCI:1@0:0:0";
    };
  };

  # iGPU OpenCL via Mesa rusticl (built-in, hardware.graphics.enable = true)

  # ── Ollama (本地 LLM 推理，CUDA) ──────────────────────────
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    user = "ollama";  # 静态用户（btrfs 子卷需要 chown，DynamicUser 不可行）
    group = "ollama";
    host = "0.0.0.0";  # 靠防火墙收口到 tailscale0
    loadModels = [ "qwen3.6:27b-q4_K_M" ];  # 显式锁定量化（NixOS 可复现性）
    syncModels = true;  # 强制声明==实际，移除未声明模型
    environmentVariables = {
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_MAX_LOADED_MODELS = "1";
      CUDA_VISIBLE_DEVICES = "0";
      OLLAMA_ORIGINS = "*";  # tailnet 内可信
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 11434 ];

  # ── Desktop ────────────────────────────────────────────────

  custom.desktop.enable = true;
  custom.desktop.dark_variant = "moon";

  # ── User ───────────────────────────────────────────────────

  users.users.fugui = {
    isNormalUser = true;
    homeMode = "750";
    linger = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    openssh.authorizedKeys.keys = [
      keys.users.fugui-github
      keys.users.fugui
      keys.users.fugui-desktop
    ];
  };

  home-manager.users.fugui = {
    imports = [ ../../home ];
    custom.qmd.enable = true;
  };

  home-manager.backupFileExtension = "hm-bak";

  # ── Remote deploy ──────────────────────────────────────────

  security.sudo = {
    wheelNeedsPassword = false;
    execWheelOnly = true;
  };

  # ── Filesystem ─────────────────────────────────────────────

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [
      "/"
      "/data/annex"
    ];
    interval = "monthly";
  };

  # ── Tailscale Serve (QMD MCP) ──────────────────────────────
  # Exposes qmd-mcp (localhost:8181) to tailnet via HTTPS.
  # Requires HTTPS certificates enabled in Tailscale admin console:
  #   https://login.tailscale.com/admin/settings/general
  # (one-time per tailnet, not nixifiable — human auth required).
  # tailscale serve --bg stores config in tailscaled state;
  # survives reboot. Idempotent re-run on every activation.
  #
  # Boot race: tailscaled.service reports "active" before the node
  # reaches BackendState == Running (login + DERP + tailscale0 up).
  # `tailscale serve` called during that window fails with
  # "unexpected state: NoState". We gate on `tailscale status`
  # (returns 0 only at Running), mirroring nixpkgs' own
  # tailscaled-autoconnect unit. Restart=on-failure keeps retrying
  # until tailscale comes up (mihomo/Tailscale boot ordering).
  # Ref: https://github.com/tailscale/tailscale/issues/11504
  systemd.services.tailscale-serve-qmd = {
    description = "Tailscale Serve for QMD MCP (localhost:8181)";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.tailscale ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 10;
    };
    script = ''
      for i in $(seq 1 60); do
        if tailscale status --peers=false >/dev/null 2>&1; then
          exec tailscale serve --bg localhost:8181
        fi
        sleep 1
      done
      echo "tailscale not online after 60s; will retry" >&2
      exit 1
    '';
  };
}
