{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../modules/river.nix
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.11";

  hardware.graphics = {
    enable = true;
    enable32Bit =true;
    extraPackages = with pkgs; [ 
      mesa
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };
  
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
  };
  
  home-manager.users.a = {
    imports = [ ../../home ];
  };

}
