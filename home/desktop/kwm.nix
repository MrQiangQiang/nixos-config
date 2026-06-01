{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  d = palette.dark;
  l = palette.dawn;
  darkZON = pkgs.replaceVars ./config/kwm-config.zon {
    inherit (d) base surface text rose foam highlight_high highlight_med;
  };
  lightZON = pkgs.replaceVars ./config/kwm-config.zon {
    inherit (l) base surface text rose foam highlight_high highlight_med;
  };
in
lib.mkIf isDesktopEnabled {
  home.packages = with pkgs; [
    kwm
    kwim
    libnotify
  ];

  xdg.configFile."theme/kwm-config-dark.zon".source = darkZON;
  xdg.configFile."theme/kwm-config-light.zon".source = lightZON;
}
