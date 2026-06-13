{ inputs, ... }:

let
  mkHost = import ../lib/mkHost.nix;
in
{
  flake.nixosConfigurations.laptop-1 = mkHost {
    inherit inputs;
    hostName = "laptop-1";
    system = "x86_64-linux";
    extraModules = [
      ./laptop-1/default.nix
    ];
  };

  flake.nixosConfigurations.desktop-1 = mkHost {
    inherit inputs;
    hostName = "desktop-1";
    system = "x86_64-linux";
    extraModules = [
      ./desktop-1/default.nix
    ];
  };
}

