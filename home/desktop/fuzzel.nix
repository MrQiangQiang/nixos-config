{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  p = palette.dark;
in
lib.mkIf isDesktopEnabled {
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "monospace:size=12";
        prompt = "> ";
        dpi-aware = "auto";
      };
      colors = {
        background = "${p.base}ff";
        text = "${p.text}ff";
        match = "${p.pine}ff";
        selection = "${p.pine}ff";
        selection-text = "${p.text}ff";
      };
    };
  };
}
