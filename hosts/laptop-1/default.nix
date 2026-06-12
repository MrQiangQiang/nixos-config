{ config, lib, pkgs, ... }: let
  keys = import ../../secrets/keys.nix;
in {
  imports = [
    ../../modules/desktop.nix
    ../../modules/proxy.nix
    ../../modules/im.nix
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.11";

  # Skylake HD 530 i915 驱动 workaround
  # 禁用 RC6/PSR/FBC 电源管理，防止 KMS 初始化时死锁
  # 参考: https://static.vivaolinux.com.br/dica/Travamentos-completos-no-Linux-com-Intel-HD-520530-Skylake-solucao-definitiva/
  boot.kernelParams = [
    "i915.enable_rc6=0"    # 禁用 RC6 渲染 C-state（主因：KMS init 死锁）
    "i915.enable_psr=0"    # 禁用面板自刷新（次因：显示管线死锁）
    "i915.powersave=0"     # 禁用 FBC+HWP（代价：+2-5W 功耗，换稳定性）
  ];

  hardware.graphics.extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
  ];

  custom.desktop.enable = true;
  custom.desktop.dark_variant = "moon";

  users.users.fugui = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    openssh.authorizedKeys.keys = [
      keys.users.fugui-github
      keys.users.fugui
    ];
  };

  home-manager.users.fugui = {
    imports = [ ../../home ];
  };

  home-manager.backupFileExtension = "hm-bak";
}
