{ ... }:
{
  perSystem = { pkgs, ... }: {
    packages.kwm = pkgs.callPackage ./kwm,nix {};
  };
}
