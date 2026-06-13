{
  hostName,
  system,
  users ? { },
  extraModules ? [ ],
  inputs,
  ...
}:

let
  lib = inputs.nixpkgs.lib;
in
lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs; };
  modules = [
    ../modules/locale.nix
    ../modules/core-utils.nix
    ../modules/fonts.nix
    ../modules/opencode.nix
    ../modules/system.nix
    ../modules/ssh.nix
    inputs.agenix.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
    {
      nixpkgs.overlays = [
        inputs.self.overlays.default
        inputs.nix-vscode-extensions.overlays.default
      ];
      nixpkgs.config.allowUnfree = true;

      networking.hostName = hostName;
      networking.nameservers = lib.mkDefault [ "223.5.5.5" "119.29.29.29" ];
      networking.networkmanager.enable = lib.mkDefault true;
      networking.firewall.enable = lib.mkDefault true;

      hardware.enableRedistributableFirmware = true;

      environment.variables = {
        EDITOR = "hx";
        VISUAL = "hx";
      };

      time.timeZone = lib.mkDefault "Asia/Shanghai";

      boot.loader = {
        systemd-boot = {
          enable = lib.mkDefault true;
          editor = true;
          configurationLimit = 10;
        };
        efi.canTouchEfiVariables = lib.mkDefault true;
        timeout = lib.mkDefault 3;
      };

      nix.settings = {
        experimental-features = [ "nix-command" "flakes" ];
        trusted-users = [
          "root"
          "@wheel"
        ];
        substituters = lib.mkDefault [
          "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=10"
          "https://mirror.sjtu.edu.cn/nix-channels/store?priority=20"
          "https://mirrors.ustc.edu.cn/nix-channels/store?priority=30"
          "https://cache.nixos.org?priority=40"
        ];
      };

      users.users = users;

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
      };
    }
  ] ++ extraModules;
}
