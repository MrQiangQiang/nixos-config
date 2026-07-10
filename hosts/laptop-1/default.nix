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
  ];

  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-vaapi-driver
  ];

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
