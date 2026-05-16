{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  cfg = osConfig.custom.desktop or {};
in
{
  home.stateVersion = "25.11";
  home.packages = lib.mkIf ( cfg.enable or false) (with pkgs; [
    river
    kwm
    foot
    waybar
    swaybg
    firefox
  ]);

  xdg.configFile = lib.mkIf ( cfg.enable or false) {
    "kwm/config.zon".source = ./config/kwm-config.zon;
  };
}
