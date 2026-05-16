{
  perSystem = { pkgs, ... }: {
    packages = {
      kwm = pkgs.callPackage ./kwm.nix {};
      river = pkgs.callPackage ./river.nix {};
    };
  };

  flake.overlays.default = final: prev: {
    kwm = final.callPackage ./kwm.nix {};
    river = final.callPackage ./river.nix {};
  };
}
