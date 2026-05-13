{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.river;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      pkgs.kwm
      waybar
      swaybg
      foot
      firefox
    ];

    wayland.windowManager.river = {
      enable = true;
      systemdIntegration = true;
     
      settings = {              
        terminal = "${pkgs.foot}/bin/foot";
       
        border = {
          "color-focused" = "0x93cee9";
          "color-unfocused" = "0x444444";
          "width" = 2;
        };
       
        keybinds = {         
          normal = {
            "Super Return" = ''spawn "${pkgs.foot}/bin/foot"'';
            "Super Q" = "close";
            "Super+Shift E" = "exit";
            "Super J" = "focus-view next";
            "Super K" = "focus-view previous";
            "Super+Shift J" = "swap next";
            "Super+Shift K" = "swap previous";
          }
          // builtins.foldl' (
            acc: i:
            let 
              tag = toString i;
            in
            acc // {
              "Super ${tag}" = "set-focused-tags ${tag}";
              "Super+Shift ${tag}" = "set-view-tags ${tag}";
            }
          ) {} (lib.range 1 9); 
       
          "pointer" = {
            "Super BTN_LEFT" = "move-view";
            "Super BTN_RIGHT" = "resize-view";
          };  
        };
          
        spawn = [
          ''"${pkgs.swaybg}/bin/swaybg" -c "#1e1e2e"''
          ''"${pkgs.waybar}/bin/waybar"''
          ''"${if cfg.windowManager "kwm"
               then pkgs.kwm
               else pkgs.rivertile}/bin/${cfg.windowManager}"''
        ];
      };
         
      extraConfig = ''
        riverctl spawm-tagmask 0
        riverctl spawm-tagmask none
      '';
    };    
  };
}
