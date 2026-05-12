{ inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    packages.kwm = pkgs.callPackage ./kwm.nix { zig-overlay = inputs.zig-overlay; };
  };
}
