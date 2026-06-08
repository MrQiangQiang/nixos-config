{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
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

      # Restore TTY palette after compositor exits. DRM fb helper resets the
      # hardware cmap to kernel defaults on drm_lastclose(), overwriting our
      # custom palette. Re-apply from mode.txt so the TTY is correct immediately.
      # NOTE: Cannot use `exec kwm` here — we need the shell to survive so the
      # restore function runs after kwm exits.
      restore_tty_palette() {
          if [ "$TERM" = "linux" ]; then
              _mode=$(cat ~/.cache/darkman/mode.txt 2>/dev/null || echo dark)
              if [ "$_mode" = "light" ]; then
                  printf '${palette.tty.light}'
              else
                  printf '${palette.tty.dark}'
              fi
              clear
          fi
      }
      kwm
      restore_tty_palette
    '';
  };
}
