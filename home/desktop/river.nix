{
  config,
  lib,
  pkgs,
  osConfig,
  ... 
}:

let
  cfg = osConfig.custom.river or {};
in
lib.mkIf ( cfg.enable or false ) {  
  home.packages = with pkgs; [ river ];
}
