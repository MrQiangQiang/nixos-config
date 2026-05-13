{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.custom.river;
in
{ 
  options.custom.river = {
    enable = lib.mkEnableOption "Enable River compositor";
    windowManager = lib.mkOption {
      type = lib.types.enum [ "kwm" "rivertile" ];
      default = "kwm";
    };
  };
      
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.river ];
  };
}

