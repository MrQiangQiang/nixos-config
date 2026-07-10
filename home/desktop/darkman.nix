{
  config,
  lib,
  pkgs,
  osConfig,
  palette,
  ...
}:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  cfgHome = config.xdg.configHome;

  # rm -f before ln -sf prevents self-referencing symlinks when target
  # already exists as a symlink to a directory (the -f flag on ln does not
  # help in this case — ln follows directory symlinks and creates inside).
  link = source: target: ''
    mkdir -p $(${pkgs.coreutils}/bin/dirname ${target})
    ${pkgs.coreutils}/bin/rm -f ${target}
    ${pkgs.coreutils}/bin/ln -sf ${source} ${target}
  '';

  signal = sig: cmd: ''
    if ${pkgs.procps}/bin/pgrep -x ${cmd} >/dev/null 2>&1; then
      ${pkgs.coreutils}/bin/kill -${sig} $(${pkgs.procps}/bin/pgrep -x ${cmd})
    fi
  '';

  applyTheme =
    mode:
    let
      isDark = mode == "dark";
      theme =
        {
          dark ? null,
          light ? null,
        }:
        "${cfgHome}/${if isDark then dark else light}";
    in
    ''
      ${link (theme {
        dark = "theme/kwm-config-dark.zon";
        light = "theme/kwm-config-light.zon";
      }) "${cfgHome}/kwm/config.zon"}
      ${signal "SIGUSR1" "kwm"}
      ${signal "SIGUSR1" "kwm-status"}

      ${link (theme {
        dark = "theme/mako-config-dark";
        light = "theme/mako-config-light";
      }) "${cfgHome}/mako/config"}
      ${pkgs.mako}/bin/makoctl reload 2>/dev/null || true

      ${link (theme {
        dark = "theme/fuzzel-config-dark.ini";
        light = "theme/fuzzel-config-light.ini";
      }) "${cfgHome}/fuzzel/fuzzel.ini"}

      ${link (theme {
        dark = "theme/networkmanager-dmenu-config-dark.ini";
        light = "theme/networkmanager-dmenu-config-light.ini";
      }) "${cfgHome}/networkmanager-dmenu/config.ini"}

      ${link (theme {
        dark = "theme/wob-config-dark.ini";
        light = "theme/wob-config-light.ini";
      }) "${cfgHome}/wob/wob.ini"}
      systemctl --user restart wob 2>/dev/null || true

      ${link (theme {
        dark = "theme/foot-dark.ini";
        light = "theme/foot-light.ini";
      }) "${cfgHome}/foot/foot.ini"}
      ${signal (if isDark then "SIGUSR1" else "SIGUSR2") "foot"}

      # rmpc: ln -sf theme + IPC broadcast (config_watcher ignores ln -sf).
      ${link (theme {
        dark = "theme/rmpc-dark.ron";
        light = "theme/rmpc-light.ron";
      }) "${cfgHome}/rmpc/themes/rose-pine.ron"}
      ${config.programs.rmpc.package}/bin/rmpc remote set theme ${cfgHome}/rmpc/themes/rose-pine.ron 2>/dev/null || true

      # mpv/uosc: ln -sf only (mpv reads config at startup, no runtime switch).
      ${link (theme {
        dark = "theme/uosc-dark.conf";
        light = "theme/uosc-light.conf";
      }) "${cfgHome}/mpv/script-opts/uosc.conf"}

      # mpv background-color: ln -sf (letterbox follows darkman via include).
      ${link (theme {
        dark = "theme/mpv-colors-dark.conf";
        light = "theme/mpv-colors-light.conf";
      }) "${cfgHome}/mpv/theme-colors.conf"}

      # GTK CSS override (tooltip colors + file picker accept button contrast).
      # Symlinked to ~/.config/gtk-3.0/gtk.css — GTK apps read it at startup.
      # Runtime switching does NOT work on Wayland (no GtkSettings bridge from
      # gsettings to GTK), but startup is correct. xdg-desktop-portal-gtk is a
      # persistent D-Bus service — restart it (or re-login) after first deploy.
      ${link (theme {
        dark = "theme/gtk-dark.css";
        light = "theme/gtk-light.css";
      }) "${cfgHome}/gtk-3.0/gtk.css"}

      # System color-scheme. GTK applications (and Firefox content processes
      # via xdg-desktop-portal-gtk) read this to determine prefers-color-scheme.
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme "${
        if isDark then "prefer-dark" else "prefer-light"
      }"
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme "${
        if isDark then palette.gtk.dark_name else palette.gtk.light_name
      }"
      ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/gtk-application-prefer-dark-theme "${
        if isDark then "true" else "false"
      }"
    '';
in
lib.mkIf isDesktopEnabled {
  services.darkman = {
    enable = true;
    settings = {
      lat = osConfig.custom.desktop.latitude;
      lng = osConfig.custom.desktop.longitude;
    };
    darkModeScripts.dark-theme = applyTheme "dark";
    lightModeScripts.light-theme = applyTheme "light";
  };

  xdg.desktopEntries.darkman = {
    name = "Toggle darkman";
    genericName = "Toggle dark mode";
    comment = "Toggle dark mode via darkman";
    exec = "darkman toggle";
    icon = "darkman";
    terminal = false;
    categories = [ "Settings" ];
  };

  xdg.dataFile."icons/hicolor/scalable/apps/darkman.svg".source = ./darkman.svg;
}
