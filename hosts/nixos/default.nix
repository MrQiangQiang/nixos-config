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
    ];
  };
  
  home-manager.users.a = {
    imports = [ ../../home/river.nix ];
    home.stateVersion = "25.11";
  };

}
