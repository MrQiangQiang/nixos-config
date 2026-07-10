{
  config,
  lib,
  pkgs,
  osConfig,
  palette,
  ...
}:

let
  isDesktopEnabled = osConfig.custom.desktop.enable;
  schemaDir = osConfig.custom.desktop.schemaDir or "";
  dataHome = config.xdg.dataHome;
  sessionVars = config.home.sessionVariablesPackage;
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
      . ${sessionVars}/etc/profile.d/hm-session-vars.sh

      export XDG_CURRENT_DESKTOP=river
      export XDG_SESSION_TYPE=wayland
      export GSETTINGS_SCHEMA_DIR=${schemaDir}

      unset GTK_IM_MODULE

      dbus-update-activation-environment --systemd XDG_CURRENT_DESKTOP XDG_SESSION_TYPE WAYLAND_DISPLAY GSETTINGS_SCHEMA_DIR XDG_DATA_DIRS QT_IM_MODULE XMODIFIERS

      # import-environment sets WAYLAND_DISPLAY in the systemd manager environment,
      # which is the single source of truth for all user services — always current,
      # survives reexec. No need for a separate env file.
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

      # Cleanup after compositor exits. wlroots sets VT keyboard mode to
      # K_MEDIUMRAW on startup but may not restore it on exit, leaving the
      # TTY keyboard-unresponsive. trap EXIT ensures cleanup runs whether
      # kwm exits normally, crashes, or is signaled.
      cleanup() {
          kbd_mode -u 2>/dev/null || true
          systemctl --user stop graphical-session.target 2>/dev/null || true
          systemctl --user unset-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE GSETTINGS_SCHEMA_DIR XDG_DATA_DIRS QT_IM_MODULE XMODIFIERS 2>/dev/null || true
          # Restore TTY palette after compositor exits. drm_lastclose() resets
          # hardware LUT to kernel defaults (linear gradient), overwriting our
          # custom palette. Re-apply from mode.txt + clear for a clean screen.
          # Redirect to /dev/tty explicitly in case stdout is not the TTY device.
          if [ "$TERM" = "linux" ]; then
              _mode=$(cat ~/.cache/darkman/mode.txt 2>/dev/null || echo dark)
              if [ "$_mode" = "light" ]; then
                  printf '${palette.tty.light}' > /dev/tty 2>/dev/null
              else
                  printf '${palette.tty.dark}' > /dev/tty 2>/dev/null
              fi
              clear > /dev/tty 2>/dev/null
          fi
      }
      trap cleanup EXIT

      kwm
    '';
  };
}
