{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.desktop;
in
{
  options.custom.desktop = {
    enable = lib.mkEnableOption "Wayland desktop environment";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.river;
      description = "The river package to use";
    };
    dark_variant = lib.mkOption {
      type = lib.types.enum [ "main" "moon" ];
      default = "main";
      description = "Rose Pine dark variant: main (standard) or moon (deeper, higher contrast)";
    };
    latitude = lib.mkOption {
      type = lib.types.float;
      default = 31.2;
      description = "Latitude for darkman and gammastep";
    };
    longitude = lib.mkOption {
      type = lib.types.float;
      default = 121.5;
      description = "Longitude for darkman and gammastep";
    };
    schemaDir = lib.mkOption {
      type = lib.types.str;
      default = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/gsettings-desktop-schemas-${pkgs.gsettings-desktop-schemas.version}/glib-2.0/schemas";
      readOnly = true;
      description = "GSETTINGS_SCHEMA_DIR path (read-only, derived from package)";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      pkgs.polkit_gnome
    ];
    programs.dconf.enable = true;
    services.displayManager.sessionPackages = [ cfg.package ];
    security.polkit.enable = true;
    security.pam.services.waylock = {};
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.darkman ];
      config.river = {
        "org.freedesktop.impl.portal.Settings" = [ "darkman" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "default" = [ "darkman" "gtk" "wlr" ];
      };
    };
  };
}
