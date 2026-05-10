{
  description = "My Nixos configuration";

  inputs = {
    nixpkg.url = "github:Nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, disko, ... } @inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ 
        ./hosts/nixos/configuration.nix
        ./hosts/nixos/hardware-configuration.nix
        home-manager.nixosModules.home-manager
      ];      
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
