{ config, inputs, lib,  ... }:
{
  flake.modules.nixos.river = { config, lib, pkgs, inputs, ... }:
    let
      cfg = config.custom.river;
    in
    { 
      options.custom.river = {
        enable = lib.mkEnableOption "Enable The River Wayland compositor and its window manager";
        windowManager = lib.mkOption {
          type = lib.types.enum [ "kwm" "rivertile" ];
          default = "kwm";
        };
        kwmConfig = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
	  default = null;
        };
      };
      
      config = lib.mkIf cfg.enable {
        home-manager.users.a = { pkgs, ... }: {
          home.packages = with pkgs; [
            river
            waybar
            swaybg
            foot
            firefox
          ] ++ lib.optional (cfg.windowManager == "kwm") inputs.self.packages.${pkgs.system}.kwm;
          
          xdg.configFile = lib.mkMerge [
            (lib.mkIf cfg.windowManager == "kwm" && cfg.kwmConfig != null) {
	      "kwm/config.zon".source = cfg.kwmConfig;
	    })
            { 
              "river/init" = { 
                text = ''
	          #!/bin/sh
             
	          waybar &
	          swaybg -c '#1e1e2e' &
	          ${if cfg.windowManager == "kwm" then "kwm" else "rivertile"} &

	          riverctl border-color-focused 0x93cee9
	          riverctl border-color-unfocused 0x444444
	          riverctl border-width 2
       
                  riverctl map normal Super Return Spawn "${pkgs.foot}/bin/foot"
                  riverctl map normal Super Q close
                  riverctl map normal Super+Shift E exit
                  riverctl map normal Super J focus-view next
                  riverctl map normal Super K focus-view previous
                  riverctl map normal Super+Shift J swap next
                  riverctl map normal Super+Shift K swap previous
                  for i in $(seq 1 9); do
                    riverctl map normal Super $i set-focused-tags $i
                    riverctl map normal Super+Shift $i set-view-tags $i
                  done
	          riverctl map-pointer normal Super BTN_LEFT move-view
                  riverctl map-pointer normal Super BTN_RIGHT resize-view
                '';
                executable = true;
              };  
            }
          ];
        };
      };
}
