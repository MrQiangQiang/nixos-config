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

  environment.variables = {
    http_proxy = "http://192.168.0.101:1082";
    https_proxy = "http://192.168.0.101:1082";
    no_proxy = "localhost,127.0.0.1,::1";
  };

  systemd.services.nix-daemon.serviceConfig = {
    Environment = [
      "http_proxy=http://192.168.0.101:1082"
      "https_proxy=http://192.168.0.101:1082"
      "no_proxy=localhost,127.0.0.1,::1"
    ];
  };
}
