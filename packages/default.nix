{ inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    packages.kwm = pkgs.callPackage ./kwm,nix {
      src = inputs.kwm-src;
    };
  };
}
