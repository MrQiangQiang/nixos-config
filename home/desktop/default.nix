{ config, lib, pkgs, osConfig, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  palette = import ./palette.nix { inherit osConfig; };
in
{
  imports = [
    ./river.nix
    ./kwm.nix
    ./waylock.nix
    ./mako.nix
    ./fuzzel.nix
    ./wob.nix
    ./swayidle.nix
    ./kanshi.nix
    ./screenshot.nix
    ./clipboard.nix
    ./gammastep.nix
    ./foot.nix
    ./firefox.nix
    ./filemanager.nix
    ./gtk.nix
    ./darkman.nix
  ];

  _module.args.palette = palette;
}
