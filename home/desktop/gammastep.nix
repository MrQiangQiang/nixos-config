{ config, lib, pkgs, osConfig, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
in
lib.mkIf isDesktopEnabled {
  services.gammastep = {
    enable = true;
    provider = "manual";
    latitude = 31.2;
    longitude = 121.5;
    temperature = {
      day = 5500;
      night = 3500;
    };
  };
}
