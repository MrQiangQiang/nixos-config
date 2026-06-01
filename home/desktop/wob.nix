{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  d = palette.dark;
  l = palette.dawn;
  mkWobConfig = colors: {
    "" = {
      timeout = 1000;
      anchor = "top right";
      margin = 10;
      padding = 5;
      border_size = 2;
      bar_padding = 5;
      background_color = "${colors.base}ff";
      bar_color = "${colors.pine}ff";
      border_color = "${colors.highlight_high}ff";
    };
  };
in
lib.mkIf isDesktopEnabled {
  home.packages = [ pkgs.brightnessctl ];

  services.wob = {
    enable = true;
  };

  xdg.configFile."theme/wob-config-dark.ini" = {
    source = pkgs.writeText "wob-config-dark.ini" (
      lib.generators.toINI {} (mkWobConfig d)
    );
  };

  xdg.configFile."theme/wob-config-light.ini" = {
    source = pkgs.writeText "wob-config-light.ini" (
      lib.generators.toINI {} (mkWobConfig l)
    );
  };
}
