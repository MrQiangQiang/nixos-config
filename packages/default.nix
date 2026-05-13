{
  perSystem = { pkgs, ... }: {
    packages = {
      kwm = pkgs.callPackage ./kwm.nix {};
      river = pkgs.callPackage ./river.nix {};
    };
  };
}
