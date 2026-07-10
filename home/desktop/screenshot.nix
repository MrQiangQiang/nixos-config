{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  isDesktopEnabled = osConfig.custom.desktop.enable;
in
lib.mkIf isDesktopEnabled {
  home.packages = with pkgs; [
    grim
    slurp

    # Region screenshot → clipboard (with lock to prevent concurrent instances)
    (writeShellScriptBin "screenshot-region" ''
      lock="''${XDG_RUNTIME_DIR:-/tmp}/screenshot-region.lock"
      if ! mkdir "$lock" 2>/dev/null; then exit 0; fi
      trap 'rmdir "$lock" 2>/dev/null' EXIT
      region=$(${slurp}/bin/slurp)
      [ -z "$region" ] && exit 1
      ${grim}/bin/grim -g "$region" - | ${wl-clipboard}/bin/wl-copy
      ${libnotify}/bin/notify-send "截图" "已复制到剪贴板"
    '')

    # Color picker → clipboard + notification (hyprpicker: magnifier cursor, click to pick)
    hyprpicker
    (writeShellScriptBin "colorpick" ''
      color=$(${hyprpicker}/bin/hyprpicker -a -f hex -n)
      [ -z "$color" ] && exit 1
    '')
  ];
}
