{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  d = palette.dark;
  l = palette.dawn;
  waylock-theme = pkgs.writeShellScriptBin "waylock-theme" ''
    # Prevent duplicate instances when both "lock" and "before-sleep" events fire
    if ${pkgs.procps}/bin/pgrep -x waylock > /dev/null; then exit 0; fi
    mode=$(${pkgs.darkman}/bin/darkman get 2>/dev/null || echo "dark")
    # Fork waylock into background so swayidle -w doesn't block on this command.
    # swaylock has -f (fork) for this; waylock does not, so we fork manually.
    # A brief sleep ensures waylock registers with pgrep before the script exits,
    # preventing race conditions with duplicate invocations.
    case "$mode" in
      light) ${pkgs.waylock}/bin/waylock -init-color 0x${l.base} -input-color 0x${l.pine} -fail-color 0x${l.love} &;;
      *)     ${pkgs.waylock}/bin/waylock -init-color 0x${d.base} -input-color 0x${d.pine} -fail-color 0x${d.love} &;;
    esac
    ${pkgs.coreutils}/bin/sleep 0.1
  '';
in
lib.mkIf isDesktopEnabled {
  home.packages = [ waylock-theme ];
  # WAYLAND_DISPLAY from systemd manager environment (set by import-environment)
  # is the single source of truth — always current, survives reexec.
  # XDG_RUNTIME_DIR is required by swayidle to locate the Wayland socket.
  systemd.user.services.swayidle = {
    Unit.ConditionEnvironment = lib.mkForce "WAYLAND_DISPLAY";
    Unit.StartLimitIntervalSec = 0;
    Service.Environment = [ "XDG_RUNTIME_DIR=/run/user/%U" ];
  };
  services.swayidle = {
    enable = true;
    timeouts = [
      { timeout = 300; command = "${waylock-theme}/bin/waylock-theme"; }
      { timeout = 600; command = "${pkgs.wlopm}/bin/wlopm --off '*'"; resumeCommand = "${pkgs.wlopm}/bin/wlopm --on '*'"; }
    ];
    events = {
      "before-sleep" = "${waylock-theme}/bin/waylock-theme";
      "lock" = "${waylock-theme}/bin/waylock-theme";
      "after-resume" = "${waylock-theme}/bin/waylock-theme; ${pkgs.wlopm}/bin/wlopm --on '*'";
    };
  };
}
