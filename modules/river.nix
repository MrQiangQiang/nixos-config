{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.river;
  riverPkg = pkgs.callPackage ../packages/river.nix {};
in
{ 
  options.custom.river = {
    enable = lib.mkEnableOption "Enable River compositor";
    windowManager = lib.mkOption {
      type = lib.types.enum [ "kwm" "rivertile" ];
      default = "kwm";
    };
  };
      
  config = lib.mkIf cfg.enable {
    programs.river = {
      enable = true;
      package = riverPkg;
    };
    
    services.dbus.enable = true;
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
    };
  };
}

