{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
in
lib.mkIf isDesktopEnabled {
  gtk = {
    enable = true;
    theme = {
      name = palette.gtk.dark_name;
      package = pkgs.rose-pine-gtk-theme;
    };
    iconTheme = {
      name = "rose-pine-icons";
      package = pkgs.rose-pine-gtk-theme;
    };
  };

  qt = {
    enable = true;
    platformTheme = "gtk";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };
}
