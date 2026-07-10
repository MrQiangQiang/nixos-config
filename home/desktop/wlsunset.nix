{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  isDesktopEnabled = osConfig.custom.desktop.enable;
in
lib.mkIf isDesktopEnabled {
  # WAYLAND_DISPLAY from systemd manager environment (set by import-environment)
  # is the single source of truth — always current, survives reexec.
  systemd.user.services.wlsunset = {
    Unit.ConditionEnvironment = lib.mkForce "WAYLAND_DISPLAY";
    Unit.StartLimitIntervalSec = 0;
    Service.Environment = [ "XDG_RUNTIME_DIR=/run/user/%U" ];
  };
  services.wlsunset = {
    enable = true;
    latitude = osConfig.custom.desktop.latitude;
    longitude = osConfig.custom.desktop.longitude;
    temperature = {
      day = 6500;
      night = 4500;
    };
  };
}
