{ config, lib, pkgs, osConfig, ... }:
let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
in
lib.mkIf isDesktopEnabled {
  programs.foot = { 
    enable = true;
    settings.main.font = "monospace:size=16";
  };
}
