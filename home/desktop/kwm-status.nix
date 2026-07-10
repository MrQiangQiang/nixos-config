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
  d = palette.dark;
  l = palette.dawn;

  # Color scheme: palette semantic colors with state-driven overrides.
  # KWM requires ^#RRGGBBAA (8-digit hex), so append "ff" alpha suffix.
  # Normal = pine/foam (cool), Warning = gold (warm), Error = love (red).
  # WiFi signal strength is NOT color-coded — community best practice
  # (Waybar/dwm/polybar) uses color for connected/disconnected only,
  # not signal gradient. Signal info is low-value (user can't act on it
  # from the bar) and KWM bar has no tooltip for detail display.
  mkColors = c: {
    net_ok = c.pine + "ff";
    net_off = c.love + "ff";
    px_ok = c.foam + "ff"; # mihomo running
    px_crash = c.love + "ff"; # mihomo crashed (exclamation icon)
    px_off = c.subtle + "ff"; # mihomo stopped intentionally (globe)
    bat_high = c.foam + "ff";
    bat_mid = c.gold + "ff";
    bat_low = c.love + "ff";
    bat_chg = c.gold + "ff";
    time = c.subtle + "ff";
  };

  darkColors = mkColors d;
  lightColors = mkColors l;

  kwmStatusSock = "$XDG_RUNTIME_DIR/kwm-status.sock";

  # Nerd Font icons: Font Awesome range (U+F000-U+F2FF).
  # Maple Mono NF CN is a COMPLETE Nerd Font build (v7.9) with full
  # FA + MDI + Octicons coverage. FA is used for guaranteed reliability.
  # Must use actual UTF-8 characters, not \uXXXX escapes.

  ICON_WIFI = ""; # fa-wifi (U+F1EB)

  ICON_PX_ON = ""; # fa-shield (U+F132)
  ICON_PX_CRASH = ""; # fa-exclamation-triangle (U+F071)
  ICON_PX_OFF = ""; # fa-globe (U+F0AC)

  ICON_BAT_FULL = ""; # fa-battery-full (U+F240)
  ICON_BAT_34 = ""; # fa-battery-three-quarters (U+F241)
  ICON_BAT_HALF = ""; # fa-battery-half (U+F242)
  ICON_BAT_14 = ""; # fa-battery-quarter (U+F243)
  ICON_BAT_EMPTY = ""; # fa-battery-empty (U+F244)
  ICON_BAT_CHG = ""; # fa-bolt (U+F0E7)

  # KWM FIFO buffer limit: 256 bytes (bar.zig status_buffer). Current max
  # output ~90 bytes. Adding new modules requires checking this constraint.

  kwm-status = pkgs.writeShellScriptBin "kwm-status" ''
    FIFO="${kwmStatusSock}"

    # Set USR1 handler before any blocking command. Without this,
    # SIGUSR1 during sleep 2 kills the process (default signal action).
    reload_colors() {
      case "$(${pkgs.darkman}/bin/darkman get 2>/dev/null)" in
        light)
          NET_OK="${lightColors.net_ok}"
          NET_OFF="${lightColors.net_off}"
          PX_OK="${lightColors.px_ok}"; PX_CRASH="${lightColors.px_crash}"
          PX_OFF="${lightColors.px_off}"
          BAT_HIGH="${lightColors.bat_high}"; BAT_MID="${lightColors.bat_mid}"
          BAT_LOW="${lightColors.bat_low}"; BAT_CHG="${lightColors.bat_chg}"
          TIME="${lightColors.time}"
          ;;
        *)
          NET_OK="${darkColors.net_ok}"
          NET_OFF="${darkColors.net_off}"
          PX_OK="${darkColors.px_ok}"; PX_CRASH="${darkColors.px_crash}"
          PX_OFF="${darkColors.px_off}"
          BAT_HIGH="${darkColors.bat_high}"; BAT_MID="${darkColors.bat_mid}"
          BAT_LOW="${darkColors.bat_low}"; BAT_CHG="${darkColors.bat_chg}"
          TIME="${darkColors.time}"
          ;;
      esac
    }
    trap reload_colors USR1

    # Wait for NetworkManager to stabilize after boot.
    ${pkgs.coreutils}/bin/sleep 2

    # Auto-detect battery.
    BAT_PATH=""
    BAT_HAS_CAPACITY=0
    for b in /sys/class/power_supply/BAT*; do
      if [ -d "$b" ] && [ -f "$b/present" ] && [ "$(${pkgs.coreutils}/bin/cat "$b/present" 2>/dev/null)" = "1" ]; then
        BAT_PATH="$b"
        [ -f "$b/capacity" ] && BAT_HAS_CAPACITY=1
        break
      fi
    done

    reload_colors

    while true; do
      # ── Network ──────────────────────────────────────────────
      # States: connected (WiFi/Ethernet) / disconnected
      # Color: connected=pine, disconnected=love
      # Signal strength is NOT color-coded (community best practice).
      net_i="${ICON_WIFI}"; net_c=$NET_OFF  # default: disconnected
      net_state=$(LC_ALL=C ${pkgs.networkmanager}/bin/nmcli -t -f STATE g 2>/dev/null)

      case "$net_state" in
        connected|connecting) net_c=$NET_OK ;;
      esac

      # ── Proxy (mihomo) ───────────────────────────────────────
      # 3-state: running / crashed / stopped
      # Node health is managed internally by mihomo (url-test + fallback).
      # Use http://127.0.0.1:9090/ui/ (Metacubexd) for node-level management.
      px_i="${ICON_PX_OFF}"; px_c=$PX_OFF  # default: stopped
      px_state=$(${pkgs.systemd}/bin/systemctl is-active mihomo 2>/dev/null || echo "unknown")
      if [ "$px_state" = "active" ]; then
        # Running normally — shield, foam
        px_i="${ICON_PX_ON}"; px_c=$PX_OK
      elif ${pkgs.systemd}/bin/systemctl --quiet is-failed mihomo 2>/dev/null; then
        # Crashed — exclamation-triangle, love
        px_i="${ICON_PX_CRASH}"; px_c=$PX_CRASH
      fi
      # else: stopped intentionally — globe, subtle (default)

      # ── Battery ──────────────────────────────────────────────
      bat_i=""; bat_c=$BAT_HIGH; bat_s=""
      if [ -n "$BAT_PATH" ]; then
        if [ "$BAT_HAS_CAPACITY" = "1" ]; then
          cap=$(${pkgs.coreutils}/bin/cat "$BAT_PATH/capacity" 2>/dev/null || echo 0)
        else
          chg=$(${pkgs.coreutils}/bin/cat "$BAT_PATH/charge_now" 2>/dev/null || echo 0)
          ful=$(${pkgs.coreutils}/bin/cat "$BAT_PATH/charge_full" 2>/dev/null || echo 1)
          [ "$ful" -gt 0 ] 2>/dev/null && cap=$(( chg * 100 / ful )) || cap=0
        fi
        stat=$(${pkgs.coreutils}/bin/cat "$BAT_PATH/status" 2>/dev/null || echo "")
        if [ "$stat" = "Charging" ]; then
          bat_i="${ICON_BAT_CHG}"; bat_c=$BAT_CHG; bat_s="+"
        elif [ "$cap" -gt 80 ] 2>/dev/null; then bat_i="${ICON_BAT_FULL}"; bat_c=$BAT_HIGH
        elif [ "$cap" -gt 60 ] 2>/dev/null; then bat_i="${ICON_BAT_34}"; bat_c=$BAT_HIGH
        elif [ "$cap" -gt 40 ] 2>/dev/null; then bat_i="${ICON_BAT_HALF}"; bat_c=$BAT_MID
        elif [ "$cap" -gt 20 ] 2>/dev/null; then bat_i="${ICON_BAT_14}"; bat_c=$BAT_MID
        else bat_i="${ICON_BAT_EMPTY}"; bat_c=$BAT_LOW; fi
      else
        cap=""
      fi

      # ── Time ─────────────────────────────────────────────────
      time=$(LC_TIME=C ${pkgs.coreutils}/bin/date +"%a %b %d %I:%M %p")

      # ── Build FIFO output ────────────────────────────────────
      out=""
      out="''${out}^#''${net_c}''${net_i}^#!"
      out="''${out}  ^#''${px_c}''${px_i}^#!"
      if [ -n "$cap" ]; then
        out="''${out}  ^#''${bat_c}''${bat_i} ''${cap}%''${bat_s}^#!"
      fi
      out="''${out}  ^#''${TIME}''${time}"

      printf '%s\n' "$out" > "$FIFO" 2>/dev/null || true
      ${pkgs.coreutils}/bin/sleep 5
    done
  '';
in
lib.mkIf isDesktopEnabled {
  home.packages = [
    kwm-status
  ];

  systemd.user.services.kwm-status = {
    Unit = {
      Description = "KWM bar status writer";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      # Preserve existing FIFO inode across service restarts. KWM opens
      # the FIFO with O_RDWR (prevents EOF), so its fd stays valid as
      # long as the inode survives. Deleting the FIFO (old ExecStartPre
      # rm -f) created a new inode on restart, orphaning KWM's fd and
      # permanently breaking the status bar. Only recreate if the file
      # is missing or not a named pipe.
      ExecStart = pkgs.writeShellScript "kwm-status-start" ''
        while [ ! -e "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]; do
          sleep 0.5
        done
        if [ ! -p ${kwmStatusSock} ]; then
          ${pkgs.coreutils}/bin/rm -f ${kwmStatusSock}
          ${pkgs.coreutils}/bin/mkfifo -m 600 ${kwmStatusSock}
        fi
        exec 3<> ${kwmStatusSock}
        exec ${kwm-status}/bin/kwm-status
      '';
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
