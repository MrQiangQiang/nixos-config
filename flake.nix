{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      # 仓库已更名为 git-hooks.nix (cachix/git-hooks.nix)。
      # flakeModule 选项仍为 pre-commit.settings (未改名,保留别名兼容)。
      url = "github:cachix/git-hooks.nix";
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
            ];
            config.allowUnfree = true;
          };

          formatter = inputs.nixpkgs.legacyPackages.${system}.nixfmt-tree;

          apps.disko = {
            type = "app";
            program = lib.getExe inputs'.disko.packages.disko;
            meta.description = "Declarative disk partitioning — run `nix run .#disko` on a fresh host";
          };

          pre-commit.settings.hooks = {
            nixfmt.enable = true;
            statix = {
              enable = true;
              # 显式指定 statix.toml 路径(hook 不会自动发现配置文件)
              # toString 将 path 字面量转为 store path 字符串,供 statix --config 读取
              settings.config = toString ./statix.toml;
            };
            # noLambdaPatternNames: 抑制 NixOS module 标准参数的未使用误报
            # (module 系统 { config, lib, pkgs, ... }: 参数是接口约定,即使未使用也保留)
            # deadnix -L 抑制 lambda attrset pattern 检查;home-manager 2026-06 起改用 nixf-diagnose。
            deadnix = {
              enable = true;
              settings.noLambdaPatternNames = true;
            };
          };
        };
    };
}
