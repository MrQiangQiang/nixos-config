{ config, lib, pkgs, osConfig, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  waylock-cmd = "${pkgs.waylock}/bin/waylock -init-color 0x000000 -input-color 0x427b58 -fail-color 0xcc3333";
in
lib.mkIf isDesktopEnabled {
  services.swayidle = {
    enable = true;
    timeouts = [
      { timeout = 300; command = waylock-cmd; }
    ];
    events = {
      "before-sleep" = waylock-cmd;
    };
  };
}
