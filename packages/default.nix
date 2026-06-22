{
  perSystem = { pkgs, ... }: {
    packages = {
      kwm = pkgs.callPackage ./kwm.nix { };
      kwim = pkgs.callPackage ./kwim.nix { };
      river = pkgs.callPackage ./river.nix { };
      trae-cn = pkgs.callPackage ./trae-cn.nix { };
    };
  };

  flake.overlays.default = final: prev: {
    kwm = final.callPackage ./kwm.nix { };
    kwim = final.callPackage ./kwim.nix { };
    river = final.callPackage ./river.nix { };
    trae-cn = final.callPackage ./trae-cn.nix { };

    # trae-cn 是预编译 Electron 应用,运行时依赖 openssl 1.1(EOL,有已知漏洞)。
    # nixpkgs 在 openssl_1_1 的 meta.knownVulnerabilities 中标记了这些漏洞,
    # 会导致 nix build 报错。此处移除 knownVulnerabilities 以允许构建。
    # 安全缓解:仅在 trae-cn 的 buildFHSEnv 沙箱内使用,不暴露给系统其他部分。
    openssl_1_1_unsecure = prev.openssl_1_1.overrideAttrs (old: {
      meta = builtins.removeAttrs old.meta [ "knownVulnerabilities" ];
    });
  };
}
