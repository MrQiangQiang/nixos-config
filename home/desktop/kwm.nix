{ config, lib, pkgs, osConfig, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
in
lib.mkIf isDesktopEnabled {
  home.packages = with pkgs; [
    kwm
    kwim
    (writeShellScriptBin "polkit-gnome-authentication-agent-1" ''
      exec ${polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 "$@"
    '')
    (writeShellScriptBin "screenshot-region" ''
      region=$(${slurp}/bin/slurp)
      ${grim}/bin/grim -g "$region" - | ${wl-clipboard}/bin/wl-copy
    '')
  ];
  xdg.configFile."kwm/config.zon".source = ./config/kwm-config.zon;
}
