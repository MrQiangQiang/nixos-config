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
  boot.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];

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

  # ── Ollama ─────────────────────────────────────────────────

  systemd.services.ollama.serviceConfig.ProtectHome = lib.mkForce "read-only";

  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    home = "/home/fugui/.ollama";
    models = "/home/fugui/.ollama/models";
    environmentVariables = {
      CUDA_VISIBLE_DEVICES = "0";
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_MAX_LOADED_MODELS = "1";
    };
  };

  environment.sessionVariables = {
    CUDA_VISIBLE_DEVICES = "0";
  };

  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
  ];

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

  users.users.ollama = {
    isSystemUser = true;
    group = "ollama";
    extraGroups = [ "users" ];
  };
  users.groups.ollama = { };

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

  # ── HDD health monitoring ──────────────────────────────────
  # smartd auto-detects all SMART-capable devices (HDD + NVMe).
  # No need to list devices explicitly — autodetect = true (default).
  services.smartd.enable = true;

  # ── Tailscale proxy (mihomo 已运行) ────────────────────────

  systemd.services.tailscaled.environment = {
    HTTPS_PROXY = "http://127.0.0.1:7890";
  };
}
