{
  config,
  lib,
  pkgs,
  osConfig,
  ... 
}:

let
  isRiverEnabled = osConfig.custom.river.enable or false;
in
lib.mkIf isRiverEnabled {
  wayland.windowManager.river = {
    enable = true;
    systemd.enable = true;
    spawn = [
      "swaybg -m color -c '#FF0000'"
      "waybar"
    ];
    run = "kwm";
  }; 
}
