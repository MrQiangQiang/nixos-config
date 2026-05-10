{
  description = "My Nixos configuration";

  inputs = {
    nixpkg.url = "github:Nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # disko = {
    #  url = "github:nix-community/disko";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      system = "x86_64-linux";
      
      perSystem = { config, self`, inputs`, pkgs, system, ... }: {
        _module.args,pkgs = pkgs;
      };      
   
      flake = {
        nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/nixos/hardware-configuration.nix
            ./hosts/nixos/configuration.nix
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.a = { config, pkg, ... }: {
                  home.stateVersion = "25.11";
                  home.packages = [ pkg.git, pkg.neovim ];    
                  programs.bash.enable = true;  
	        };
              };	 
            }
          ];
        };
      }; 
    };

  # nixConfig = {
  #  substituters = [
  #    "https://mirror.sjtu.edu.cn/nix-channels/store?priority=10"
  #    "https://mirror.tuna.tsinghua.edu.cn/nix-channels/store?priority=11" 	
  #    "https://mirror.ustc.edu.cn/nix-channels/store?priority=12"
  #    "https://cache.nixos.org"
  #  ];
   
  #  trusted-public-keys = [
  #    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  #  ];
  #};
}
