{ config, lib, pkgs, ... }: {
  imports = [
    ../../modules/desktop.nix
    ../../modules/proxy.nix
    ../../modules/im.nix
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.11";

  hardware.graphics.extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
  ];

  custom.desktop.enable = true;
  custom.desktop.dark_variant = "moon";

  users.users.a = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKPlCRJnNW/V6jTl90yd1CMjIuorkNPJRs/dAgAbGnBx fugui@github.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJvALtc74c420xWoDLT6mwGO/Mf7JemicsoeFjFo87Ez fugui@nixos"
    ];
  };

  home-manager.users.a = {
    imports = [ ../../home ];
  };
}
