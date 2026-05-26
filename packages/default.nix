{
  perSystem = { pkgs, ... }: {
    packages = {
      kwm = pkgs.callPackage ./kwm.nix {};
      river = pkgs.callPackage ./river.nix {};
      trae-cn = pkgs.callPackage ./trae-cn.nix {};
    };
  };

  flake.overlays.default = final: prev: {
    kwm = final.callPackage ./kwm.nix {};
    river = final.callPackage ./river.nix {};
    trae-cn = final.callPackage ./trae-cn.nix {};
    openssl_1_1_unsecure = prev.openssl_1_1.overrideAttrs (old: {
      meta = builtins.removeAttrs old.meta [ "knownVulnerabilities" ];
    });
  };
}
