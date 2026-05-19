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
  };
  
  xdg.configFile."river/init" = {
    executable = true;
    text = ''
      #!/bin/sh
      swaybg -m color -c "#FF0000" &
      waybar &
      
      exec kwm
    '';
  }; 
}
