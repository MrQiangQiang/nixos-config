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
    windowManager = lib.mkOption {
      type = lib.types.enum [ "kwm" "rivertile" ];
      default = "kwm";
    };
  };
      
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    services.displayManager.sessionPackages = [ cfg.package ];
    services.seatd.enable = true;    
    services.dbus.enable = true;

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
      config.common.default = "*";
    };
  };
}

