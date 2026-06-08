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

  # Dark Reader settings JSON, deployed to ~/.config/dark-reader/settings.json
  # Import via: Dark Reader Settings → See all options → Import → select this file
  # After import, Dark Reader reads settings from browser.storage (not this file)
  darkReaderSettings = pkgs.replaceVars ./config/dark-reader-settings.json {
    dark_base = d.base;
    dark_text = d.text;
    dawn_base = l.base;
    dawn_text = l.text;
  };

  # GTK tooltip CSS: overrides GTK theme tooltip colors for Firefox NAC tooltips.
  # NAC tooltips use CSS system colors (InfoBackground/InfoText) from GTK,
  # which userChrome.css cannot style. These files override GTK's tooltip widget
  # colors. Runtime switching does NOT work on Wayland (no GtkSettings bridge
  # from gsettings to GTK), but Firefox reads gtk.css at startup — correct.
  gtkTooltipLight = pkgs.replaceVars ./config/gtk-tooltip-light.css {
    dawn_overlay = "#${l.overlay}";
    dawn_text = "#${l.text}";
    dawn_highlight_med = "#${l.highlight_med}";
  };
  gtkTooltipDark = pkgs.replaceVars ./config/gtk-tooltip-dark.css {
    dark_overlay = "#${d.overlay}";
    dark_text = "#${d.text}";
    dark_highlight_med = "#${d.highlight_med}";
  };
in
lib.mkIf isDesktopEnabled {
  xdg.configFile."dark-reader/settings.json".source = darkReaderSettings;

  xdg.configFile."theme/gtk-tooltip-light.css".source = gtkTooltipLight;
  xdg.configFile."theme/gtk-tooltip-dark.css".source = gtkTooltipDark;

  programs.firefox = {
    enable = true;
    configPath = ".config/mozilla/firefox";
    policies.ExtensionSettings = {
      "addon@darkreader.org" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
        installation_mode = "normal_installed";
      };
    };
    profiles.default = {
      id = 0;
      isDefault = true;
      userChrome = rosePineUserChrome;
      userContent = rosePineUserContent;
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "extensions.activeThemeID" = "default-theme@mozilla.org";
        # 1 = tabs replace titlebar (no separate titlebar above tabs)
        # With River's org_kde_kwin_server_decoration patch, GTK3 does not
        # create CSD widgets, so Firefox renders tabs at the top edge.
        "browser.tabs.inTitlebar" = 1;
      };
    };
  };
}
