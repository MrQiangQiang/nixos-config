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
  xdg.configFile."river/init" = {
    executable = true;
    text = ''
      #!/bin/sh
      
      export XDG_CURRENT_DESKTOP=river
      export XDG_SESSION_TYPE=wayland
   
      swaybg -m color -c "#FF0000" &
      waybar &
      
      exec kwm
    '';
  }; 
}
