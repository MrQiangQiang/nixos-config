{ inputs, ... }:

let
  mkHost = import ../lib/mkHost.nix { inherit inputs; };
in
{
  flake.nixosConfigurations.nixos = mkHost {
    hostName = "nixos";
    system = "x86_64-linux";
    extraModules = [
      ./nixos/default.nix
    ];
  };
}

