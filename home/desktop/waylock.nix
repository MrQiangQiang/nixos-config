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
  home.packages = [ pkgs.waylock ];
}
