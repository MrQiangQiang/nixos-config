{ inputs, ... }:

let
  mkHost = import ../lib/mkHost.nix;
in
{
  flake.nixosConfigurations.nixos = mkHost {
    inherit inputs;
    hostName = "nixos";
    system = "x86_64-linux";
    extraModules = [
      ./nixos/default.nix
    ];
  };
}

