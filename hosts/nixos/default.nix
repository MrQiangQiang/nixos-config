{
  config,
  lib,
  pkgs,
  ...
}:

let
  mirrorConfigText = ''
    [[registry]]
    prefix = "docker.io"
    location = "docker.io"
    
    [[registry.mirror]]
    location = "https://docker.1ms.run"

    [[registry.mirror]]
    location = "https://docker.m.daocloud.io"

    [[registru.mirror]]
    location = "https://docker.xuanyuan.me"
  '';
in
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
    containers = {
      enable = true;
      containersConf.settings = {
        containers.unqualified-search-registries = [ "docker.io" ];
      };
    };
  };

  environment.etc."containers/registries.conf".text = mirrorConfigText;

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
