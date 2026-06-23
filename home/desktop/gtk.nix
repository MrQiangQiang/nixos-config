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
  schemaDir = osConfig.custom.desktop.schemaDir or "";
in
lib.mkIf isDesktopEnabled {
  dconf.enable = true;

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
