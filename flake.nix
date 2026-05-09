{
  description = "My Nixos configuration";

  inputs = {
    nixpkg.url = "git+https://mirrors.nju.edu.cn/git/nixpkgs.git?ref=nixos-25.11&shallow=1";
    flake-parts.url = "git+https://mirrors.nju.edu.cn/git/flake-parts.git?shallow=1";
    home-manager = {
      url = "git+https://mirrors.nju.edu.cn/git/home-manager.git?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # disko = {
    #   url = "github:nix-community/disko";
    #     inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = inputs @ { flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        inputs.home-manager.flakeModules.home-manager
        ./hosts
        ./modules
        ./home
      ];      
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
