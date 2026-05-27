{ config, lib, pkgs, osConfig, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
in
lib.mkIf isDesktopEnabled {
  xdg.configFile."river/init" = {
    executable = true;
    text = ''
      #!/bin/sh
      export XDG_CURRENT_DESKTOP=river
      export XDG_SESSION_TYPE=wayland

      systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=river XDG_SESSION_TYPE=wayland

      systemctl --user start graphical-session.target || true
      systemctl --user restart xdg-desktop-portal.service || true
      systemctl --user restart xdg-desktop-portal-gtk.service || true

      exec kwm
    '';
  };
}
