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
        pkgs.xdg-desktop-portal-wlr
      ];
      config = {
        common.default = "*";
        river.default = [ "wlr" "gtk" ];
      };
    };
    
    environment.etc."river/init".text = ''
      #!/bin/sh
      systemctl --user import-environment WAYLAND_DISPLAY 
XDG_CURRENT_DESKTOP XDG_SESSION_TYPE
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY 
XDG_CURRENT_DESKTOP=river XDG_SESSION_TYPE=wayland

      systemctl --user restart xdg-desktop-portal.service || true
      systemctl --user restart xdg-desktop-portal-gtk.service || true
    '';
  };
}

