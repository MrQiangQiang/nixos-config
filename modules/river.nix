{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.river;
in
{ 
  options.custom.river = {
    enable = lib.mkEnableOption "Enable River compositor";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.river;
      description = "The river package to use";
    };
  };
      
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    services.displayManager.sessionPackages = [ cfg.package ];
    security.polkit.enable = true;

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
      config = {
        common.default = "*";
        river.default = [ "wlr" "gtk" ];
      };
    };
  };
}

