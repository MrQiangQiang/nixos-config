{
  config,
  lib,
  pkgs,
  osConfig,
  palette,
  ...
}:

let
  isDesktopEnabled = osConfig.custom.desktop.enable;
  d = palette.dark;
  l = palette.dawn;

  mkFootColors = c: {
    foreground = c.text;
    background = c.base;
    # regular colors — strictly match official rose-pine/foot
    regular0 = c.overlay; # black (Overlay)
    regular1 = c.love; # red (Love)
    regular2 = c.foam; # green (Foam)
    regular3 = c.gold; # yellow (Gold)
    regular4 = c.pine; # blue (Pine)
    regular5 = c.iris; # magenta (Iris)
    regular6 = c.rose; # cyan (Rose)
    regular7 = c.text; # white (Text)
    # bright colors — official lighter variants
    bright0 = c.bright_overlay;
    bright1 = c.bright_love;
    bright2 = c.bright_foam;
    bright3 = c.bright_gold;
    bright4 = c.bright_pine;
    bright5 = c.bright_iris;
    bright6 = c.bright_rose;
    bright7 = c.bright_text;
    flash = c.gold;
    cursor = "${c.base} ${c.text}";
  };

  footSettings = {
    main = {
      font = "monospace:size=16";
      initial-color-theme = "dark";
    };
    colors-dark = mkFootColors d;
    colors-light = mkFootColors l;
  };

  footDarkIni = pkgs.writeText "foot-dark.ini" (lib.generators.toINI { } footSettings);
  footLightIni = pkgs.writeText "foot-light.ini" (
    lib.generators.toINI { } (
      footSettings
      // {
        main = footSettings.main // {
          initial-color-theme = "light";
        };
      }
    )
  );
in
lib.mkIf isDesktopEnabled {
  home.packages = [ pkgs.foot ];

  xdg.configFile."theme/foot-dark.ini".source = footDarkIni;
  xdg.configFile."theme/foot-light.ini".source = footLightIni;
}
