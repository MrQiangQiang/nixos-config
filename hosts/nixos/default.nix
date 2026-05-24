{ config, lib, pkgs, ... }: {
  imports = [
    ../../modules/river.nix
    ../../modules/proxy.nix
    ../../modules/im.nix
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.11";

  hardware.graphics.extraPackages = with pkgs; [
      intel-media-driver 
      intel-vaapi-driver
  ];
  
  custom.river.enable = true;

  users.users.a = {
    isNormalUser = true;
    extraGroups = [ 
      "wheel"
      "networkmanager"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKP1CRJnNW/V6jT190yd1CMjuorkNPJRs/dAgAbGnBx fugui@github.com"
    ];
  };
  
  home-manager.users.a = {
    imports = [ ../../home ];
  };
}
