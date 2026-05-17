{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  isRiverEnabled = osConfig.custom.river.enable or false;
in
lib.mkIf isRiverEnabled {
  home.packages = with pkgs; [ firefox ];
}
