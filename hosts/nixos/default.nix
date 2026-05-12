{ inputs, ... }: {
  imports = [
    inputs.self.flakeModules.nixos.river
    ./hardware-configuration.nix
  ];

  networking.hostName = "nixos";
  networking.nameservers = [ "8,8,8,8" "1.1.1.1" ];
  networking.networkmanager.enable = true;
  
  time.timeZone = "Asia/Shanghai";
  
  hardware.enableRedistributableFirmware = true;

  boot.loader = {
    system-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  
  custom.river = {
    enable = true;
    windowManager = "kwm";
  };
  
  users.users.a = {
    isNormalUsr = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
  };
  
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  system.stateVersion = "25.11";
}
