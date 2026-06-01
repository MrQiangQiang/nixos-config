{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  p = palette.dark;
in
lib.mkIf isDesktopEnabled {
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
        background_color = "${p.base}ff";
        bar_color = "${p.pine}ff";
        border_color = "${p.pine}ff";
      };
    };
  };
}
