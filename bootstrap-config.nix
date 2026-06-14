{ config, pkgs, lib, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-partlabel/disk-main-root";
      fsType = "btrfs";
      options = [ "compress=zstd" "noatime" "subvol=@" ];
    };
    "/boot" = {
      device = "/dev/disk/by-partlabel/disk-main-boot";
      fsType = "ext4";
    };
    "/boot/efi" = {
      device = "/dev/disk/by-partlabel/disk-main-ESP";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
    "/home" = {
      device = "/dev/disk/by-partlabel/disk-main-root";
      fsType = "btrfs";
      options = [ "compress=zstd" "noatime" "subvol=@home" ];
    };
    "/nix" = {
      device = "/dev/disk/by-partlabel/disk-main-root";
      fsType = "btrfs";
      options = [ "compress=zstd" "noatime" "subvol=@nix" ];
    };
    "/var/cache" = {
      device = "/dev/disk/by-partlabel/disk-main-root";
      fsType = "btrfs";
      options = [ "compress=zstd" "noatime" "subvol=@var_cache" ];
    };
    "/var/log" = {
      device = "/dev/disk/by-partlabel/disk-main-root";
      fsType = "btrfs";
      options = [ "compress=zstd" "noatime" "subvol=@var_log" ];
    };
    "/home/fugui/.ollama" = {
      device = "/dev/disk/by-partlabel/disk-main-root";
      fsType = "btrfs";
      options = [ "compress=zstd" "noatime" "subvol=@ollama" ];
    };
    "/data/cold" = {
      device = "/dev/disk/by-partlabel/disk-main-root";
      fsType = "btrfs";
      options = [ "compress=zstd" "noatime" "subvol=@data_cold" ];
    };
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "desktop-1";
  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.fugui = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJvALtc74c420xWoDLT6mwGO/Mf7JemicsoeFjFo87Ez fugui@laptop-1"
    ];
  };

  security.sudo = {
    wheelNeedsPassword = false;
    execWheelOnly = true;
  };

  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "zh_CN.UTF-8";
  hardware.enableRedistributableFirmware = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@wheel" ];
    substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
  };

  system.stateVersion = "26.11";
}
