{
  hostName,
  system,
  users ? { },
  extraModules ? [ ],
  inputs,
  ...
}:

inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs; };
  modules = [
    ../modules/locale.nix
    ../modules/core-utils.nix
    ../modules/fonts.nix
    ../modules/system.nix
    ../modules/ssh.nix
    inputs.agenix.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
    {
      nixpkgs.overlays = [
        inputs.self.overlays.default
        inputs.nix-vscode-extensions.overlays.default
      ];
      nixpkgs.config.allowUnfree = true;

      networking.hostName = hostName;
      networking.nameservers = [ "8.8.8.8" "1.1.1.1" ];
      networking.networkmanager.enable = true;

      hardware.enableRedistributableFirmware = true;

      time.timeZone = "Asia/Shanghai";

      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };

      nix.settings = {
        experimental-features = [ "nix-command" "flakes" ];
        trusted-users = [
          "root"
          "@wheel"
        ];
        substituters = [
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
