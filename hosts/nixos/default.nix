{
  config,
  lib,
  pkgs,
  ...
}:

{
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
  

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
    containers.enable = true;
  };

  environment.systemPackages = with pkgs; [
    distrobox
  ];
  
  users.users.a = {
    isNormalUser = true;
    extraGroups = [ 
      "wheel"
      "networkmanager"
      "podman"
    ];
    autoSubUidGidRange = true;
    linger = true;
  };
  
  home-manager.users.a = {
    imports = [ ../../home ];
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = "thunar.desktop";
      };
    };
  };
}
