{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  isDesktopEnabled = osConfig.custom.desktop.enable;
in
lib.mkIf isDesktopEnabled {
  home.packages = [
    (pkgs.writeShellScriptBin "polkit-gnome-authentication-agent-1" ''
      exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 "$@"
    '')
  ];
}
