{ config, lib, pkgs, osConfig, ... }:

let
  palette = import ./desktop/palette.nix { inherit osConfig; };
in
{
  imports = [
    ./desktop
    ./dev
    ./shell
  ];

  _module.args.palette = palette;

  home.stateVersion = "25.11";
}
