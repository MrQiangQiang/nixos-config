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
lib.mkIf isRiverEnabled {
  home.packages = with pkgs; [ firefox ];
}
