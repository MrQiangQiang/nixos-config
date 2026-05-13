{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }: 
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux"];
      imports = [ 
        inputs.home-manager.flakeModules.home-manager
        ./modules
        ./packages
        ./hosts
      ];
    };
}
