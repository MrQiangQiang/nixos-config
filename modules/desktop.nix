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
      description = "Latitude for darkman and wlsunset";
    };
    longitude = lib.mkOption {
      type = lib.types.float;
      default = 121.5;
      description = "Longitude for darkman and wlsunset";
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

    # River broadcasts org_kde_kwin_server_decoration protocol (via patch),
    # which GTK3 recognizes. GTK3's gdk_wayland_display_prefers_ssd() returns
    # TRUE, so GTK3 apps do not create CSD decoration widgets. kwm draws
    # the border. MOZ_GTK_TITLEBAR_DECORATION=system tells Firefox to
    # request SSD decoration mode from the compositor.
    #
    # IMPORTANT: "none" is WRONG - it makes SetCustomTitlebar() return early
    # without calling gtk_window_set_decorated(false), so GTK3 still renders
    # the default CSD decoration with no way to control it.
    environment.sessionVariables.MOZ_GTK_TITLEBAR_DECORATION = "system";

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
