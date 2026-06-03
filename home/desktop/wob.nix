{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;

  mkWobConfig = colors: let
    c = colors;
  in {
    "" = {
      timeout = 1000;
      anchor = "top right";
      margin = 10;
      border_offset = 5;
      border_size = 2;
      bar_padding = 5;
      background_color = "${c.base}ff";
      bar_color = "${c.pine}ff";
      border_color = "${c.highlight_high}ff";
    };
    "style.muted" = {
      background_color = "${c.base}ff";
      bar_color = "${c.love}ff";
      border_color = "${c.highlight_high}ff";
    };
  };

  wobSock = "$XDG_RUNTIME_DIR/wob.sock";
in
lib.mkIf isDesktopEnabled {
  home.packages = [ pkgs.brightnessctl pkgs.wob ];

  # Custom systemd service using exec 3<> to keep FIFO write end open.
  # This avoids the POLLHUP busy loop caused by systemd socket activation,
  # where poll() returns immediately preventing the timeout from firing
  # and OSD stays visible forever.
  systemd.user.services.wob = {
    Unit = {
      Description = "Wayland Overlay Bar";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
      StartLimitIntervalSec = 0;
    };
    Service = {
      ExecStartPre = "-${pkgs.coreutils}/bin/rm -f %t/wob.sock";
      ExecStart = pkgs.writeShellScript "wob-start" ''
        # WAYLAND_DISPLAY is inherited from systemd manager environment
        # (set by river's import-environment, always current).
        # Do NOT source wayland-env — it can be stale after rebuild.

        # Wait for Wayland display socket to exist
        while [ ! -e "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]; do
          sleep 0.5
        done

        ${pkgs.coreutils}/bin/mkfifo -m 600 ${wobSock}
        exec 3<> ${wobSock}
        exec ${pkgs.wob}/bin/wob < ${wobSock}
      '';
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  xdg.configFile."theme/wob-config-dark.ini" = {
    source = pkgs.writeText "wob-config-dark.ini" (
      lib.generators.toINI {} (mkWobConfig palette.dark)
    );
  };

  xdg.configFile."theme/wob-config-light.ini" = {
    source = pkgs.writeText "wob-config-light.ini" (
      lib.generators.toINI {} (mkWobConfig palette.dawn)
    );
  };
}
