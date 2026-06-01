{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  p = palette.dark;
in
lib.mkIf isDesktopEnabled {
  services.mako = {
    enable = true;
    settings = {
      font = "monospace 12";
      background-color = "#${p.base}ff";
      text-color = "#${p.text}ff";
      border-color = "#${p.pine}ff";
      border-size = 2;
      default-timeout = 5000;
    };
  };
}
