{ config, lib, pkgs, osConfig, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
in
lib.mkIf isDesktopEnabled {
  # WAYLAND_DISPLAY from systemd manager environment (set by import-environment)
  # is the single source of truth — always current, survives reexec.
  systemd.user.services.kanshi = {
    Unit.ConditionEnvironment = lib.mkForce "WAYLAND_DISPLAY";
    Unit.StartLimitIntervalSec = 0;
    Service.Environment = [ "XDG_RUNTIME_DIR=/run/user/%U" ];
  };
  services.kanshi = {
    enable = true;
    settings = [
      {
        profile.name = "laptop";
        profile.outputs = [{
          criteria = "eDP-1";
          status = "enable";
        }];
      }
      {
        profile.name = "desktop";
        profile.outputs = [{
          criteria = "HDMI-A-1";
          mode = "3840x2160@60";
          scale = 1.5;
          status = "enable";
        }];
      }
    ];
  };
}
