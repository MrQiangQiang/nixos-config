{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  isRiverEnabled = osConfig.config.custom.river.enable or false;
in
lib.mkIf isRiverEnable {
  home.packages = with pkgs; [ waybar ];
}
