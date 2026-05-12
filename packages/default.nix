{ inputs, ... }:
{
  perSystem = { pkgs, inputs, ... }: {
    packages.kwm = pkgs.callPackage ./kwm.nix { zig-overlay = inputs.zig-overlay; };
  };
}
