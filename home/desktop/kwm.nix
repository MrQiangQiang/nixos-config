{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  cfg = osConfig.custon.river or {};
in
lib.mkIf ( cfg.enable or false ) {
  home.packages = with pkgs; [ kwm ];
  xdg.configFile."kwm/config.zon".source = ./config/kwm-config.zon;
}
