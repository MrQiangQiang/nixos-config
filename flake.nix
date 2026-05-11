{
  description = "My Nixos configuration";

  inputs = {
    nixpkgs.url = "github:Nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    kwm.url = "github:kewuaa/kwm";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];
      imports = [ 
        inputs.home-manager.flakeModules.home-manager 
      ];

      perSystem = { config, pkgs, ... }: {
        _module.args.pkgs = pkgs;
      };      
   
      flake = {
        nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/nixos/hardware-configuration.nix
            ./hosts/nixos/configuration.nix
            inputs.home-manager.nixosModules.home-manager
            ./modules/river-kwm.nix
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.a = { pkgs, ... }: {
                  home.packages = [ pkgs.git pkgs.neovim ];    
                  programs.bash.enable = true;  
	        };
              };	 
            }
          ];
        };
      }; 
    };
}
