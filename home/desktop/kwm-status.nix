{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  d = palette.dark;
  l = palette.dawn;

  # Color scheme: palette semantic colors with state-driven overrides.
  # Normal = pine/foam (cool), Warning = gold (warm), Error = love (red).
  mkColors = c: {
    net_ok   = c.pine;
    net_off  = c.love;
    px_ok    = c.foam;
    px_off   = c.love;
    bat_high = c.foam;
    bat_mid  = c.gold;
    bat_low  = c.love;
    bat_chg  = c.gold;
    time     = c.subtle;
  };

  darkColors  = mkColors d;
  lightColors = mkColors l;

  kwmStatusSock = "$XDG_RUNTIME_DIR/kwm-status.sock";

  kwm-status = pkgs.writeShellScriptBin "kwm-status" ''
    FIFO="${kwmStatusSock}"

    # Load color set based on current darkman mode.
    # USR1 signal from darkman triggers reload.
    reload_colors() {
      case "$(${pkgs.darkman}/bin/darkman get 2>/dev/null)" in
        light)
          NET_OK="${lightColors.net_ok}";  NET_OFF="${lightColors.net_off}"
          PX_OK="${lightColors.px_ok}";    PX_OFF="${lightColors.px_off}"
          BAT_HIGH="${lightColors.bat_high}"; BAT_MID="${lightColors.bat_mid}"
          BAT_LOW="${lightColors.bat_low}";   BAT_CHG="${lightColors.bat_chg}"
          TIME="${lightColors.time}"
          ;;
        *)
          NET_OK="${darkColors.net_ok}";  NET_OFF="${darkColors.net_off}"
          PX_OK="${darkColors.px_ok}";    PX_OFF="${darkColors.px_off}"
          BAT_HIGH="${darkColors.bat_high}"; BAT_MID="${darkColors.bat_mid}"
          BAT_LOW="${darkColors.bat_low}";   BAT_CHG="${darkColors.bat_chg}"
          TIME="${darkColors.time}"
          ;;
      esac
    }
    trap reload_colors USR1
    reload_colors

    while true; do
      # Network: nmcli connected?
      net="NET"; net_c=$NET_OK
      ${pkgs.networkmanager}/bin/nmcli -t -f STATE g general 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "^connected" || { net="OFF"; net_c=$NET_OFF; }

      # Proxy: mihomo active?
      px="PX"; px_c=$PX_OK
      ${pkgs.systemd}/bin/systemctl is-active --quiet mihomo 2>/dev/null || { px="PX!"; px_c=$PX_OFF; }

      # Battery: capacity + charging state
      bat_c=$BAT_HIGH; bat_s=""
      cap=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 100)
      stat=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "")
      if [ "$stat" = "Charging" ]; then
        bat_c=$BAT_CHG; bat_s="+"
      elif [ "$cap" -gt 60 ] 2>/dev/null; then
        bat_c=$BAT_HIGH
      elif [ "$cap" -gt 20 ] 2>/dev/null; then
        bat_c=$BAT_MID
      else
        bat_c=$BAT_LOW
      fi

      # Time
      time=$(${pkgs.coreutils}/bin/date +"%a %H:%M")

      # Output: ^#RRGGBBAA prefix per module, ^#! resets to default fg
      printf "^#%s%s^#!  ^#%s%s^#!  ^#%s%s%%''${bat_s}^#!  ^#%s%s\n" \
        "$net_c" "$net" "$px_c" "$px" "$bat_c" "$cap" "$TIME" "$time" \
        > "$FIFO" 2>/dev/null || true

      ${pkgs.coreutils}/bin/sleep 5
    done
  '';
in
lib.mkIf isDesktopEnabled {
  home.packages = [
    kwm-status

    # WiFi selector: fuzzel dmenu with nmcli. Bound to status bar left-click.
    (pkgs.writeShellScriptBin "wifi-select" ''
      ssid=$(${pkgs.networkmanager}/bin/nmcli -t -f SSID dev wifi list 2>/dev/null \
        | ${pkgs.coreutils}/bin/cut -d: -f2 \
        | ${pkgs.gnugrep}/bin/grep -v '^$' \
        | ${pkgs.fuzzel}/bin/fuzzel --dmenu -p "WiFi: " -l 10)
      [ -n "$ssid" ] && ${pkgs.networkmanager}/bin/nmcli dev wifi connect "$ssid" 2>/dev/null \
        || ${pkgs.libnotify}/bin/notify-send "WiFi" "Failed to connect to ''${ssid:-<none>}"
    '')
  ];

  systemd.user.services.kwm-status = {
    Unit = {
      Description = "KWM bar status writer";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      ExecStartPre = "-${pkgs.coreutils}/bin/rm -f %t/kwm-status.sock";
      ExecStart = pkgs.writeShellScript "kwm-status-start" ''
        while [ ! -e "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]; do
          sleep 0.5
        done
        ${pkgs.coreutils}/bin/mkfifo -m 600 ${kwmStatusSock}
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
