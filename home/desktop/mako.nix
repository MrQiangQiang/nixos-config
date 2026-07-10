{
  config,
  lib,
  pkgs,
  osConfig,
  palette,
  ...
}:

let
  isDesktopEnabled = osConfig.custom.desktop.enable;
  d = palette.dark;
  l = palette.dawn;
  mkMakoConfig = colors: {
    layer = "overlay";
    font = "monospace 12";
    background-color = "#${colors.overlay}ff";
    text-color = "#${colors.text}ff";
    border-color = "#${colors.highlight_high}ff";
    border-size = 2;
    default-timeout = 5000;
    progress-color = "over #${colors.pine}ff";
  };

  makoToText =
    settings:
    lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k}=${toString v}") settings) + "\n";

  mkMakoUrgency = colors: ''
    [urgency=high]
    border-color=#${colors.love}ff
  '';
in
lib.mkIf isDesktopEnabled {
  home.packages = [
    pkgs.mako
    pkgs.libnotify
  ];

  # Hand-written systemd service instead of services.mako:
  # services.mako creates a read-only ~/.config/mako/config symlink,
  # which conflicts with darkman's ln -sf for theme switching.
  # Type=dbus ensures systemd waits for D-Bus name registration before
  # considering the service started, matching mako's upstream service file.
  systemd.user.services.mako = {
    Unit = {
      Description = "Lightweight Wayland notification daemon";
      Documentation = "man:mako(1)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
      # Reload (not Restart) to keep D-Bus registration intact across config changes
      X-Reload-Triggers = [
        "${config.xdg.configFile."theme/mako-config-dark".source}"
        "${config.xdg.configFile."theme/mako-config-light".source}"
      ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.freedesktop.Notifications";
      ExecStart = "${pkgs.mako}/bin/mako";
      ExecReload = "${pkgs.mako}/bin/makoctl reload";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  xdg.configFile."theme/mako-config-dark" = {
    source = pkgs.writeText "mako-config-dark" (makoToText (mkMakoConfig d) + mkMakoUrgency d);
  };

  xdg.configFile."theme/mako-config-light" = {
    source = pkgs.writeText "mako-config-light" (makoToText (mkMakoConfig l) + mkMakoUrgency l);
  };
}
