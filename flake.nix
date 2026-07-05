{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    qmd = {
      url = "github:tobi/qmd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agent-lx-music = {
      url = "github:Xuepoo/agent-lx-music";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        ./packages
        ./hosts
        inputs.pre-commit-hooks.flakeModule
      ];
      perSystem =
        {
          system,
          lib,
          inputs',
          ...
        }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              inputs.self.overlays.default
              inputs.nix-vscode-extensions.overlays.default
            ];
            config.allowUnfree = true;
          };

          formatter = inputs.nixpkgs.legacyPackages.${system}.nixfmt;

          apps.disko = {
            type = "app";
            program = lib.getExe inputs'.disko.packages.disko;
            meta.description = "Declarative disk partitioning — run `nix run .#disko` on a fresh host";
          };

          pre-commit.settings.hooks = {
            nixfmt.enable = true;
          };
        };
    };
}
