{
  config,
  lib,
  pkgs,
  ...
}:
let
  keys = import ../../secrets/keys.nix;
in
{
  imports = [
    ../../modules/desktop.nix
    ../../modules/proxy.nix
    ../../modules/im.nix
    ../../modules/tailscale.nix
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.11";
  home-manager.users.fugui.home.stateVersion = "25.11";

  # ── Laptop-specific config ────────────────────────────────

  # Lid behavior — desktop machines have no lid
  services.logind.settings.Login = {
    HandleSuspendKey = "suspend";
    HandleLidSwitch = "suspend";
    HandleLidSwitchDocked = "ignore";
  };

  # Battery management — desktop machines have no battery
  services.upower.enable = true;

  # Compressed swap in RAM — laptop has limited RAM
  zramSwap.enable = true;

  # ── Hardware ──────────────────────────────────────────────

  # Skylake HD 530 i915 驱动 workaround
  # 禁用 PSR 防止 KMS 初始化死锁
  # (enable_rc6/powersave 在内核 6.18+ 已移除,日志报 unknown parameter ignored)
  boot.kernelParams = [
    "i915.enable_psr=0"
    "nvidia-drm.modeset=1"
    "modprobe.blacklist=nouveau"
    "nouveau.modeset=0"
  ];

  # GPU: GTX 950M (Maxwell GM107)
  # Maxwell 在 nixpkgs stable (595.84) 中已移除,必须用 legacy_580。
  # Wayland 下 PRIME sync 模式不可用 (X11-only),只能用 offload 模式:
  # iGPU (HD 530) 驱动显示,dGPU 通过 nvidia-offload cmd 按需调用。
  services.xserver.videoDrivers = [ "nvidia" ];
  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  hardware.nvidia = {
    open = false; # Maxwell 不支持 open kernel module
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false; # Maxwell 不支持精细电源管理
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0@0:2:0";
      nvidiaBusId = "PCI:1@0:0:0";
    };
  };

  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-vaapi-driver
  ];

  # ── NTP ────────────────────────────────────────────────────
  # 默认 0-3.nixos.pool.ntp.org 在中国网络环境下不稳定,
  # 实测 time4.cloud.tencent.com (119.28.183.184) 超时。
  networking.timeServers = [
    "ntp.aliyun.com"
    "0.cn.pool.ntp.org"
    "1.cn.pool.ntp.org"
  ];

  # ── Journal ─────────────────────────────────────────────────
  services.journald.extraConfig = ''
    SystemMaxUse=512M
    SystemKeepFree=2G
    SystemMaxFileSize=100M
    MaxRetentionSec=30day
  '';

  # ── Tailscale DERP log spam ────────────────────────────────
  # 上游已知 bug (github.com/tailscale/tailscale/issues/14623):
  # 对已移除 peer 的 DERP 路由反复输出 info 日志,无独立抑制开关。
  # LogFilterPatterns 在 systemd 260.2 可用,用 ~ 前缀过滤匹配的 MESSAGE。
  systemd.services.tailscaled.serviceConfig.LogFilterPatterns =
    "~magicsock: derp-.*does not know about peer";

  # ── Desktop ───────────────────────────────────────────────

  custom.desktop.enable = true;
  custom.desktop.dark_variant = "moon";

  # ── User ──────────────────────────────────────────────────

  # 共享 home-manager 配置见 lib/mkHost.nix

  # ── Remote deploy ──────────────────────────────────────────
  # 通过 root SSH 密钥登录实现远程部署(nixos-rebuild --target-host root@laptop-1),
  # 与 desktop-1 对称:部署密钥来自 desktop-1 的 fugui 用户。
  # 仅允许密钥登录(ProhibitRootLogin),覆盖 modules/ssh.nix 的默认 "no"。
  services.openssh.settings.PermitRootLogin = "prohibit-password";
  users.users.root.openssh.authorizedKeys.keys = [
    keys.users.fugui-desktop
  ];
}
