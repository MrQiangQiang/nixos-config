{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  d = palette.dark;
  l = palette.dawn;

  mkFootColors = c: {
    foreground = c.text;
    background = c.base;
    regular0 = c.overlay;
    regular1 = c.love;
    regular2 = c.pine;
    regular3 = c.gold;
    regular4 = c.foam;
    regular5 = c.iris;
    regular6 = c.rose;
    regular7 = c.text;
    bright0 = c.muted;
    bright1 = c.love;
    bright2 = c.pine;
    bright3 = c.gold;
    bright4 = c.foam;
    bright5 = c.iris;
    bright6 = c.rose;
    bright7 = c.text;
  };

  footSettings = {
    main = {
      font = "monospace:size=16";
      initial-color-theme = "dark";
    };
    colors-dark = mkFootColors d;
    colors-light = mkFootColors l;
  };

  footDarkIni = pkgs.writeText "foot-dark.ini" (
    lib.generators.toINI {} footSettings
  );
  footLightIni = pkgs.writeText "foot-light.ini" (
    lib.generators.toINI {} (footSettings // {
      main = footSettings.main // { initial-color-theme = "light"; };
    })
  );
in
lib.mkIf isDesktopEnabled {
  home.packages = [ pkgs.foot ];

  xdg.configFile."theme/foot-dark.ini".source = footDarkIni;
  xdg.configFile."theme/foot-light.ini".source = footLightIni;
}
