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
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      pkgs.polkit_gnome
    ];
    services.displayManager.sessionPackages = [ cfg.package ];
    security.polkit.enable = true;
    security.pam.services.waylock = {};
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.river = {
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "default" = [ "gtk" "wlr" ];
      };
    };
  };
}
