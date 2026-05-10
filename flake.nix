{
  description = "My Nixos configuration";

  inputs = {
    nixpkg.url = "github:Nixos/nixpkgs/nixos-25.11";
    # flake-parts.url = "gitub:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # disko = {
    #   url = "github:nix-community/disko";
    #     inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { self, nixpkgs, home-manager, ... } @inputs:
  {
    nixosConfiguration.nixos = nixpkgs.lib.nixosSystem {
      systems = "x86_64-linux";
      modules = [ 
        ./hosts/nixos/configuration.nix
        ./hosts/nixos/hardware-configuration.nix
        home-manager.nixosModules.home-manager
      ];      
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.sjtu.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };
}
