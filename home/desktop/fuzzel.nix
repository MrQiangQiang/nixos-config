{ config, lib, pkgs, osConfig, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
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
        background = "000000ff";
        text = "bbbbbbff";
        match = "427b58ff";
        selection = "427b58ff";
        selection-text = "eeeeeeff";
      };
    };
  };
}
