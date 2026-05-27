{ config, lib, pkgs, osConfig, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
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
        background_color = "000000ff";
        bar_color = "427b58ff";
        border_color = "427b58ff";
      };
    };
  };
}
