top@{config, lib, inputs, ...}
{
  perSystem = { pkgs, ... }: {
    packages.kwm = pkgs.callPackage ./kwm.nix { zig-overlay = top.inputs.zig-overlay; };
  };
}
