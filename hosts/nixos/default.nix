{ 
  inputs,
  config,
  pkgs,
  lib, 
  ... 
}:

{
  imports = [
    ../../modules/river.nix
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  nix.settings.substituters = [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=10"
    "https://mirror.sjtu.edu.cn/nix-channels/store?priority=20"
    "https://mirrors.ustc.edu.cn/nix-channels/store?priority=30"
    "https://cache.nixos.org?priority=40"
  ];

  networking.hostName = "nixos";
  networking.nameservers = [ "8,8,8,8" "1.1.1.1" ];
  networking.networkmanager.enable = true;
  
  time.timeZone = "Asia/Shanghai";
  
  hardware.enableRedistributableFirmware = true;

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
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
    ];
  };
  
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  system.stateVersion = "25.11";
}
