{ config, lib, pkgs, osConfig, ... }:

let
  palette = import ./desktop/palette.nix { inherit osConfig; };
  keybinds = import ./desktop/keybind-registry.nix { inherit lib; };
in
{
  imports = [
    ./desktop
    ./dev
    ./shell
  ];

  _module.args.palette = palette;
  _module.args.keybinds = keybinds;

  home.stateVersion = "26.11";
}
