{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  cfg = osConfig.custom.river or {};  
  kwm-local = pkgs.callPackage ../packages/kwm.nix {};
in
{
  config = lib.mkIf (cfg.enable or false) {
    home.packages = with pkgs; [
      kwm-local
      waybar
      swaybg
      foot
      firefox
    ];

    wayland.windowManager.river = {
      enable = true;
      systemd.enable = true;
      
      settings = {              
        terminal = "${pkgs.foot}/bin/foot";
       
        border = {
          "color-focused" = "0x93cee9";
          "color-unfocused" = "0x444444";
          "width" = 2;
        };

        default-layout = "${cfg.windowManager}";
       
        keybinds = {         
          normal = {
            "Super Return" = "spawn ${pkgs.foot}/bin/foot";
            "Super Q" = "close";
            "Super+Shift E" = "exit";
            "Super J" = "focus-view next";
            "Super K" = "focus-view previous";
            "Super+Shift J" = "swap next";
            "Super+Shift K" = "swap previous";
            "Super m" = "zoom";
          } // (builtins.listToAttrs(builtins.concatMap (i:
          let
            pow2 = n: if n == 0 then 1 else 2 * (pow2 (n - 1));
            tag = toString (pow2 (i - 1));
            index = toString i;
          in [
            { name = "Super ${index}}"; value = "set-focused-tag ${tag}"; }
            { name = "Super+Shift ${index}"; value = "set-view-tag ${tag}"; }
          ]) (lib.range 1 9))); 
       
          pointer = {
            "Super BTN_LEFT" = "move-view";
            "Super BTN_RIGHT" = "resize-view";
          };  
        };

        spawn = [
          "${pkgs.swaybg}/bin/swaybg -c '#1e1e2e'"
          "${pkgs.waybar}/bin/waybar"
          (if cfg.windowManager == "kwm"
           then "${kwm-local}/bin/kwm"
           else "${pkgs.rivertile}/bin/rivertile")
        ];
          
      };
         
      extraConfig = ''
        riverctl spawm-tagmask 0
        riverctl focus-follows-cursor always
        riverctl export XDG_CURRENT_DESKTOP river
      '';
    };    
  };
}
