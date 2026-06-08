{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  d = palette.dark;
  l = palette.dawn;
  mkMakoConfig = colors: {
    font = "monospace 12";
    background-color = "#${colors.overlay}ff";
    text-color = "#${colors.text}ff";
    border-color = "#${colors.highlight_high}ff";
    border-size = 2;
    default-timeout = 5000;
    progress-color = "over #${colors.pine}ff";
  };

  makoToText = settings: lib.concatStringsSep "\n" (
    lib.mapAttrsToList (k: v: "${k}=${toString v}") settings
  ) + "\n";

  mkMakoUrgency = colors: ''
    [urgency=high]
    border-color=#${colors.love}ff
  '';
in
lib.mkIf isDesktopEnabled {
  home.packages = [ pkgs.mako ];

  xdg.configFile."theme/mako-config-dark" = {
    source = pkgs.writeText "mako-config-dark" (makoToText (mkMakoConfig d) + mkMakoUrgency d);
  };

  xdg.configFile."theme/mako-config-light" = {
    source = pkgs.writeText "mako-config-light" (makoToText (mkMakoConfig l) + mkMakoUrgency l);
  };
}
