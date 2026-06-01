{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  p = palette.dark;
in
lib.mkIf isDesktopEnabled {
  programs.foot = {
    enable = true;
    settings = {
      main.font = "monospace:size=16";
      colors = {
        foreground = "${p.text}ff";
        background = "${p.base}ff";
        regular0 = "${p.overlay}ff";
        regular1 = "${p.love}ff";
        regular2 = "${p.pine}ff";
        regular3 = "${p.gold}ff";
        regular4 = "${p.foam}ff";
        regular5 = "${p.iris}ff";
        regular6 = "${p.rose}ff";
        regular7 = "${p.text}ff";
        bright0 = "${p.muted}ff";
        bright1 = "${p.love}ff";
        bright2 = "${p.pine}ff";
        bright3 = "${p.gold}ff";
        bright4 = "${p.foam}ff";
        bright5 = "${p.iris}ff";
        bright6 = "${p.rose}ff";
        bright7 = "${p.text}ff";
      };
    };
  };
}
