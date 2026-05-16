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

  config = lib.mkIf (cfg.enable or false) {
    home.packages = with pkgs; [
      river
      kwm
      foot
      waybar
      swaybg
      firefox
    ];
  }  
}
