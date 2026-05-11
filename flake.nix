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
          modules = [
            ./hosts/nixos/hardware-configuration.nix
            ./hosts/nixos/configuration.nix
            ./modules/river-kwm.nix
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.a = { pkgs, ... }: {
                  home.stateVersion = "25.11";
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
