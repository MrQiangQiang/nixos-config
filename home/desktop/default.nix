{ config, lib, pkgs, osConfig, ... }:

{
  imports = [
    ./river.nix
    ./kwm.nix
    ./kwm-status.nix
    ./networkmanager-dmenu.nix
    ./waylock.nix
    ./mako.nix
    ./fuzzel.nix
    ./wob.nix
    ./swayidle.nix
    ./kanshi.nix
    ./screenshot.nix
    ./clipboard.nix
    ./wlsunset.nix
    ./foot.nix
    ./firefox.nix
    ./filemanager.nix
    ./gtk.nix
    ./darkman.nix
    ./fcitx5.nix
    ./polkit.nix
    ./media-keys.nix
    ./keybind-help.nix
  ];
}
