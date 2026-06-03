{
  config,
  lib,
  pkgs,
  osConfig,
  palette,
  ...
}:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  d = palette.dark;
  l = palette.dawn;

  rosePineUserChrome = pkgs.replaceVars ./config/rose-pine-firefox-userChrome.css {
    dark_base = "#${d.base}";
    dark_surface = "#${d.surface}";
    dark_overlay = "#${d.overlay}";
    dark_muted = "#${d.muted}";
    dark_subtle = "#${d.subtle}";
    dark_text = "#${d.text}";
    dark_love = "#${d.love}";
    dark_gold = "#${d.gold}";
    dark_rose = "#${d.rose}";
    dark_pine = "#${d.pine}";
    dark_foam = "#${d.foam}";
    dark_iris = "#${d.iris}";
    dark_highlight_low = "#${d.highlight_low}";
    dark_highlight_med = "#${d.highlight_med}";
    dark_highlight_high = "#${d.highlight_high}";
    dawn_base = "#${l.base}";
    dawn_surface = "#${l.surface}";
    dawn_overlay = "#${l.overlay}";
    dawn_muted = "#${l.muted}";
    dawn_subtle = "#${l.subtle}";
    dawn_text = "#${l.text}";
    dawn_love = "#${l.love}";
    dawn_gold = "#${l.gold}";
    dawn_rose = "#${l.rose}";
    dawn_pine = "#${l.pine}";
    dawn_foam = "#${l.foam}";
    dawn_iris = "#${l.iris}";
    dawn_highlight_low = "#${l.highlight_low}";
    dawn_highlight_med = "#${l.highlight_med}";
    dawn_highlight_high = "#${l.highlight_high}";
  };

  rosePineUserContent = pkgs.replaceVars ./config/rose-pine-firefox-userContent.css {
    dark_base = "#${d.base}";
    dark_surface = "#${d.surface}";
    dark_overlay = "#${d.overlay}";
    dark_muted = "#${d.muted}";
    dark_subtle = "#${d.subtle}";
    dark_text = "#${d.text}";
    dark_love = "#${d.love}";
    dark_gold = "#${d.gold}";
    dark_rose = "#${d.rose}";
    dark_pine = "#${d.pine}";
    dark_foam = "#${d.foam}";
    dark_iris = "#${d.iris}";
    dark_highlight_low = "#${d.highlight_low}";
    dark_highlight_med = "#${d.highlight_med}";
    dark_highlight_high = "#${d.highlight_high}";
    dawn_base = "#${l.base}";
    dawn_surface = "#${l.surface}";
    dawn_overlay = "#${l.overlay}";
    dawn_muted = "#${l.muted}";
    dawn_subtle = "#${l.subtle}";
    dawn_text = "#${l.text}";
    dawn_love = "#${l.love}";
    dawn_gold = "#${l.gold}";
    dawn_rose = "#${l.rose}";
    dawn_pine = "#${l.pine}";
    dawn_foam = "#${l.foam}";
    dawn_iris = "#${l.iris}";
    dawn_highlight_low = "#${l.highlight_low}";
    dawn_highlight_med = "#${l.highlight_med}";
    dawn_highlight_high = "#${l.highlight_high}";
  };
in
lib.mkIf isDesktopEnabled {
  programs.firefox = {
    enable = true;
    configPath = ".config/mozilla/firefox";
    profiles.default = {
      id = 0;
      isDefault = true;
      userChrome = rosePineUserChrome;
      userContent = rosePineUserContent;
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "extensions.activeThemeID" = "default-theme@mozilla.org";
      };
    };
  };

  # Disable Firefox CSD (Client-Side Decorations) so kwm draws the border.
  # home.sessionVariables alone doesn't work: River doesn't source hm-session-vars.sh.
  # The River init script sources this via /etc/set-environment which reads sessionVariables.
  home.sessionVariables.MOZ_GTK_TITLEBAR_DECORATION = "none";
}
