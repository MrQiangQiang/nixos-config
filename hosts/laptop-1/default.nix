{ config, lib, pkgs, ... }: let
  keys = import ../../secrets/keys.nix;
in {
  imports = [
    ../../modules/desktop.nix
    ../../modules/proxy.nix
    ../../modules/im.nix
    ../../modules/tailscale.nix
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.11";

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
  # 禁用 RC6/PSR/FBC 电源管理，防止 KMS 初始化时死锁
  boot.kernelParams = [
    "i915.enable_rc6=0"
    "i915.enable_psr=0"
    "i915.powersave=0"
  ];

  hardware.graphics.extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
  ];

  # ── Desktop ───────────────────────────────────────────────

  custom.desktop.enable = true;
  custom.desktop.dark_variant = "moon";

  # ── User ──────────────────────────────────────────────────

  users.users.fugui = {
    isNormalUser = true;
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
  };

  home-manager.backupFileExtension = "hm-bak";
}
