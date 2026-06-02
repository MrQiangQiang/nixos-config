{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  d = palette.dark;
  l = palette.dawn;
  waylock-theme = pkgs.writeShellScriptBin "waylock-theme" ''
    mode=$(${pkgs.darkman}/bin/darkman get 2>/dev/null || echo "dark")
    case "$mode" in
      light) exec ${pkgs.waylock}/bin/waylock -init-color 0x${l.base} -input-color 0x${l.pine} -fail-color 0x${l.love};;
      *)     exec ${pkgs.waylock}/bin/waylock -init-color 0x${d.base} -input-color 0x${d.pine} -fail-color 0x${d.love};;
    esac
  '';
in
lib.mkIf isDesktopEnabled {
  home.packages = [ waylock-theme ];
  services.swayidle = {
    enable = true;
    timeouts = [
      { timeout = 300; command = "${waylock-theme}/bin/waylock-theme"; }
      { timeout = 600; command = "${pkgs.wlopm}/bin/wlopm --off '*'"; resumeCommand = "${pkgs.wlopm}/bin/wlopm --on '*'"; }
    ];
    events = {
      "before-sleep" = "${waylock-theme}/bin/waylock-theme";
    };
  };
}
