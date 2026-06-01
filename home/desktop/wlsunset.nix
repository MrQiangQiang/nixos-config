{ config, lib, pkgs, osConfig, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
in
lib.mkIf isDesktopEnabled {
  services.wlsunset = {
    enable = true;
    latitude = osConfig.custom.desktop.latitude;
    longitude = osConfig.custom.desktop.longitude;
    temperature = {
      day = 6500;
      night = 4500;
    };
  };
}
