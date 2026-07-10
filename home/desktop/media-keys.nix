{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  isDesktopEnabled = osConfig.custom.desktop.enable;
  wobSock = "$XDG_RUNTIME_DIR/wob.sock";

  getVolume = ''
    vol=$(${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
    pct=$(${pkgs.coreutils}/bin/echo "$vol" | ${pkgs.gnused}/bin/sed 's/Volume: \([0-9.]*\).*/\1/;s/\.//' | ${pkgs.gnused}/bin/sed 's/^0*//'); pct=''${pct:-0}
    if ${pkgs.coreutils}/bin/echo "$vol" | ${pkgs.gnugrep}/bin/grep -q MUTED; then
      ${pkgs.coreutils}/bin/echo "$pct muted" > ${wobSock}
    else
      ${pkgs.coreutils}/bin/echo "$pct" > ${wobSock}
    fi
  '';

  getBrightness = ''
    pct=$(${pkgs.brightnessctl}/bin/brightnessctl info 2>/dev/null | ${pkgs.gnused}/bin/sed -n 's/.*(\([0-9]*\)%).*/\1/p')
    ${pkgs.coreutils}/bin/echo "''${pct:-50}" > ${wobSock}
  '';
in
lib.mkIf isDesktopEnabled {
  home.packages = [
    # Volume
    (pkgs.writeShellScriptBin "volume-up" ''
      ${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ 2>/dev/null
      ${getVolume}
    '')
    (pkgs.writeShellScriptBin "volume-down" ''
      ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- 2>/dev/null
      ${getVolume}
    '')
    (pkgs.writeShellScriptBin "volume-mute" ''
      ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle 2>/dev/null
      ${getVolume}
    '')

    # Brightness
    (pkgs.writeShellScriptBin "brightness-up" ''
      ${pkgs.brightnessctl}/bin/brightnessctl set 5%+ 2>/dev/null
      ${getBrightness}
    '')
    (pkgs.writeShellScriptBin "brightness-down" ''
      ${pkgs.brightnessctl}/bin/brightnessctl set 5%- 2>/dev/null
      ${getBrightness}
    '')

    # Media control (MPRIS)
    # Success: mpdris2 (notifications=true) sends D-Bus notifications with
    # title+artist+cover. Failure: notify-send reports the error.
    pkgs.playerctl
    (pkgs.writeShellScriptBin "media-play-pause" ''
      if ! ${pkgs.playerctl}/bin/playerctl play-pause 2>/dev/null; then
        ${pkgs.libnotify}/bin/notify-send "播放控制" "无播放器"
      fi
    '')
    (pkgs.writeShellScriptBin "media-next" ''
      if ! ${pkgs.playerctl}/bin/playerctl next 2>/dev/null; then
        ${pkgs.libnotify}/bin/notify-send "下一曲" "当前播放器不支持切歌"
      fi
    '')
    (pkgs.writeShellScriptBin "media-prev" ''
      if ! ${pkgs.playerctl}/bin/playerctl previous 2>/dev/null; then
        ${pkgs.libnotify}/bin/notify-send "上一曲" "当前播放器不支持切歌"
      fi
    '')
  ];
}
