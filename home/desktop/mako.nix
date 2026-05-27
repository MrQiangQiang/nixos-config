{ config, lib, pkgs, osConfig, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
in
lib.mkIf isDesktopEnabled {
  services.mako = {
    enable = true;
    settings = {
      font = "monospace 12";
      background-color = "#000000ff";
      text-color = "#bbbbbbff";
      border-color = "#427b58ff";
      border-size = 2;
      default-timeout = 5000;
    };
  };
}
