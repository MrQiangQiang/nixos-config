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
  schemaDir = osConfig.custom.desktop.schemaDir;
  d = palette.dark;
  l = palette.dawn;

  # GTK CSS override — two fixes the Rose Pine GTK theme (v2.2.0) doesn't handle:
  # 1. Tooltip colors (Firefox NAC tooltips use CSS system colors from GTK)
  # 2. File picker accept button :disabled state (near-invisible contrast)
  # Deployed to ~/.config/theme/gtk-{dark,light}.css, symlinked into
  # ~/.config/gtk-3.0/gtk.css by darkman's applyTheme on mode switch.
  gtkOverrideDark = pkgs.replaceVars ./gtk/dark.css {
    dark_overlay = "#${d.overlay}";
    dark_text = "#${d.text}";
    dark_highlight_med = "#${d.highlight_med}";
  };
  gtkOverrideLight = pkgs.replaceVars ./gtk/light.css {
    dawn_overlay = "#${l.overlay}";
    dawn_text = "#${l.text}";
    dawn_highlight_med = "#${l.highlight_med}";
  };
in
lib.mkIf isDesktopEnabled {
  dconf.enable = true;

  xdg.configFile."theme/gtk-dark.css".source = gtkOverrideDark;
  xdg.configFile."theme/gtk-light.css".source = gtkOverrideLight;

  home.sessionVariables.GSETTINGS_SCHEMA_DIR = schemaDir;
  systemd.user.sessionVariables.GSETTINGS_SCHEMA_DIR = schemaDir;

  home.packages = [ pkgs.glib ];

  gtk = {
    enable = true;
    gtk2.extraConfig = ''gtk-im-module="fcitx"'';
    gtk3 = {
      extraConfig.gtk-im-module = "fcitx";
    };
    gtk4.extraConfig.gtk-im-module = "fcitx";
    theme = {
      name = palette.gtk.dark_name;
      package = pkgs.rose-pine-gtk-theme;
    };
    gtk4.theme = null;
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };
}
