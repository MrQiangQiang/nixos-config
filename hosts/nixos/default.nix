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

  hardware.graphics = {
    enable = true;
    enable32Bit =true;
    extraPackages = with pkgs; [ 
      mesa
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };
  
  custom.river = {
    enable = true;
    windowManager = "kwm";
  };
  
  users.users.a = {
    isNormalUser = true;
    extraGroups = [ 
      "wheel"
      "networkmanager"
      "video"
      "input"
      "render"
    ];
  };
  
  home-manager.users.a = {
    imports = [ ../../home/river.nix ];
    home.stateVersion = "25.11";
  };

}
