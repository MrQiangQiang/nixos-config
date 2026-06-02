{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  d = palette.dark;
in
lib.mkIf isDesktopEnabled {
  home.packages = [ pkgs.brightnessctl ];

  services.wob = {
    enable = true;
    settings = {
      "" = {
        timeout = 1000;
        anchor = "top right";
        margin = 10;
        padding = 5;
        border_size = 2;
        bar_padding = 5;
        background_color = "${d.base}ff";
        bar_color = "${d.pine}ff";
        border_color = "${d.highlight_high}ff";
      };
    };
  };
}
