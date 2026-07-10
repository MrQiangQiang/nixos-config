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
    ./hardware-configuration.nix
    ./git-annex.nix
    ./tailscale-serve.nix
  ];

  # stateVersion 记录安装时的 NixOS 版本,永不更改 (architecture.md)。
  # desktop-1 装于 nixos-unstable (26.05 发布后跟踪 26.11pre),故为 "26.11"。
  # laptop-1 装于 25.11 周期,故为 "25.11"。两主机差异是预期行为。
  system.stateVersion = "26.11";
  home-manager.users.fugui.home.stateVersion = "26.11";

  # ── Kernel ─────────────────────────────────────────────────

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "pcie_aspm=off"
    "amd_pstate=active"
    "modprobe.blacklist=nouveau"
    "nouveau.modeset=0"
  ];

  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # ── WiFi: MT7925 roaming crash workaround ─────────────────
  # mt7925e 驱动在 v7.1.x 仍有未修复的 list corruption bug，由
  # band-steering roaming（2.4GHz ↔ 5GHz AP 切换）触发：
  #   list_add corruption → kernel BUG → reboot → probe failed error -5
  # Zac Bowling 的 patch 0002/0012 已合并到 v7.1，但 crash 仍存在
  # （另一个未修复的 bug，见 crash-analysis Pattern 3 / Hung Task）。
  # 锁定 5GHz 单频段 = 锁定单一 AP = 消除 roaming 触发。
  # 移除条件：mt7925 驱动 roaming 路径修复进入 stable 内核。
  # Ref: https://zbowling.github.io/mt7925/issues/crash-analysis/
  systemd.services.wifi-mt7925-roaming-workaround = {
    description = "MT7925 roaming crash workaround: lock WiFi to 5GHz";
    after = [ "NetworkManager.service" ];
    wants = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.networkmanager ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for conn in $(nmcli -t -f NAME,TYPE con show 2>/dev/null | grep ':802-11-wireless' | cut -d: -f1); do
        nmcli connection modify "$conn" 802-11-wireless.band a 2>/dev/null || true
      done
    '';
  };

  # ── GPU: NVIDIA + AMD iGPU (PRIME Offload) ────────────────
  # 必须声明 videoDrivers，否则 hardware.nvidia 模块不激活，
  # GSP 固件不会安装到 /lib/firmware/nvidia/，导致 RmInitAdapter failed。
  # Blackwell (RTX 5090) 强制要求 open kernel module + GSP 固件。
  services.xserver.videoDrivers = [ "nvidia" ];

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
  # 模块由 lib/mkHost.nix 共享导入（options 全局可见），此处仅启用服务。
  # 包含 KEEP_ALIVE=-1 永久驻留 + ollama-prewarm.service VRAM 预加载
  custom.ollama.enable = true;

  # ── Desktop ────────────────────────────────────────────────

  custom.desktop.enable = true;
  custom.desktop.dark_variant = "moon";

  # ── User ───────────────────────────────────────────────────

  # homeMode 比 laptop 更严格(共享基础配置见 modules/users.nix)
  users.users.fugui.homeMode = "750";

  # QMD 仅 desktop 启用(共享 home-manager 配置见 lib/mkHost.nix)
  home-manager.users.fugui.custom.qmd.enable = true;

  # ── Remote deploy ──────────────────────────────────────────
  # 通过 root SSH 密钥登录实现远程部署(nixos-rebuild --target-host root@desktop-1),
  # 替代旧的 wheelNeedsPassword=false(全 wheel 组免密 sudo = 完整 root 后门)。
  # 仅允许密钥登录(ProhibitRootLogin),部署密钥来自 laptop-1 的 fugui 用户。
  services.openssh.settings.PermitRootLogin = "prohibit-password";
  users.users.root.openssh.authorizedKeys.keys = [
    keys.users.fugui
  ];

  # ── Filesystem ─────────────────────────────────────────────

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [
      "/"
      "/data/annex"
    ];
    interval = "monthly";
  };
}
