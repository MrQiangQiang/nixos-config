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

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  environment.systemPackages = with pkgs; [
    distrobox
  ];
  
  users.users.a = {
    isNormalUser = true;
    extraGroups = [ 
      "wheel"
      "networkmanager"
      "video"
      "input"
      "render"
      "seat"
      "podman"
    ];
    subUidRanges = [ { startUid = 100000; count = 65536; } ];
    subGidRanges = [ { startGid = 100000; count = 65536; } ];
  };
  
  home-manager.users.a = {
    imports = [ ../../home ];
  };

}
