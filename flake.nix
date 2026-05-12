{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    let
      import-tree = path:
        builtins.concatLists (
          builtins.attrValues (
            builtins.mapAttrs
              (name: type: 
                if type == "regular" && builtins.match ".*\\.nix" name != null
		then [ (path + "/${name}") ]
                else if type == "directory"
                then import-tree (path + "/${name}")
                else [ ]
              )
              (builtins.readDir path)	
           )  
         );
    in 
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux"];
      imports = [ 
        inputs.home-manager.flakeModules.home-manager
        ./modules/river.nix
        ./packages
      ];
      flake.nixConfig = {
        experimental-features = [ "nix-command" "flakes" ];
        substituters = [
          "https://mirror.sjtu.edu.cn/nix-channels/store"
          "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
          "https://mirrors.ustc.edu.cn/nix-channels/store"
          "https://cache.nixos.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDshjY="
        ];
      };
      flake.nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/nixos/default.nix
        ];
      };  
    };
}
