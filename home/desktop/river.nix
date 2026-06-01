{ config, lib, pkgs, osConfig, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  schemaDir = osConfig.custom.desktop.schemaDir or "";
  dataHome = config.xdg.dataHome;
in
lib.mkIf isDesktopEnabled {
  systemd.user.targets.graphical-session = {
    Unit.RefuseManualStart = lib.mkForce false;
  };

  xdg.configFile."river/init" = {
    executable = true;
    text = ''
      #!/bin/sh
      . /etc/set-environment

      export XDG_CURRENT_DESKTOP=river
      export XDG_SESSION_TYPE=wayland
      export GSETTINGS_SCHEMA_DIR=${schemaDir}

      unset GTK_IM_MODULE

      dbus-update-activation-environment --systemd XDG_CURRENT_DESKTOP XDG_SESSION_TYPE WAYLAND_DISPLAY GSETTINGS_SCHEMA_DIR XDG_DATA_DIRS QT_IM_MODULE XMODIFIERS

      systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE GSETTINGS_SCHEMA_DIR XDG_DATA_DIRS QT_IM_MODULE XMODIFIERS
      systemctl --user start graphical-session.target

      systemctl --user restart xdg-desktop-portal.service || true
      systemctl --user restart xdg-desktop-portal-gtk.service || true

      mode=$(${pkgs.darkman}/bin/darkman get 2>/dev/null || echo dark)
      case "$mode" in
        light) ${dataHome}/darkman/light-mode.d/light-theme ;;
        *) ${dataHome}/darkman/dark-mode.d/dark-theme ;;
      esac
      ${pkgs.darkman}/bin/darkman set "$mode"

      fcitx5 -d --replace 2>/dev/null &

      exec kwm
    '';
  };
}
