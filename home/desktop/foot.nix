{ config, lib, pkgs, osConfig, ... }:
let
  isRiverEnabled = osConfig.custom.river.enable or false;
in
lib.mkIf isRiverEnabled {
  programs.foot = { 
    enable = true;
    settings.main.font = "monospace:size=16";
  };
}
