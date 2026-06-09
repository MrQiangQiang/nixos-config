{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  cfgHome = config.xdg.configHome;
  dataHome = config.xdg.dataHome;

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

  applyTheme = mode: let
    isDark = mode == "dark";
    theme = { dark ? null, light ? null }: "${cfgHome}/${if isDark then dark else light}";
  in ''
    ${link (theme { dark = "theme/kwm-config-dark.zon"; light = "theme/kwm-config-light.zon"; }) "${cfgHome}/kwm/config.zon"}
    ${signal "SIGUSR1" "kwm"}

    ${link (theme { dark = "theme/mako-config-dark"; light = "theme/mako-config-light"; }) "${cfgHome}/mako/config"}
    ${pkgs.mako}/bin/makoctl reload 2>/dev/null || true

    ${link (theme { dark = "theme/fuzzel-config-dark.ini"; light = "theme/fuzzel-config-light.ini"; }) "${cfgHome}/fuzzel/fuzzel.ini"}

    ${link (theme { dark = "theme/wob-config-dark.ini"; light = "theme/wob-config-light.ini"; }) "${cfgHome}/wob/wob.ini"}
    systemctl --user restart wob 2>/dev/null || true

    ${link (theme { dark = "theme/foot-dark.ini"; light = "theme/foot-light.ini"; }) "${cfgHome}/foot/foot.ini"}
    ${signal (if isDark then "SIGUSR1" else "SIGUSR2") "foot"}

    ${link (theme { dark = "theme/fcitx5-dark"; light = "theme/fcitx5-light"; }) "${dataHome}/fcitx5/themes/rose-pine-current"}
    mkdir -p ${cfgHome}/fcitx5/conf
    ${pkgs.coreutils}/bin/printf '[ClassicUI]\nTheme=rose-pine-current\n' > ${cfgHome}/fcitx5/conf/classicui.conf
    ${pkgs.fcitx5}/bin/fcitx5 -r 2>/dev/null || true

    # GTK tooltip CSS for Firefox NAC tooltips. NAC tooltips use CSS system
    # colors (InfoBackground/InfoText) from GTK — userChrome.css cannot style them.
    # This symlink ensures gtk.css is correct at Firefox startup. Runtime switching
    # does NOT work on Wayland (no GtkSettings bridge from gsettings to GTK).
    ${link (theme { dark = "theme/gtk-tooltip-dark.css"; light = "theme/gtk-tooltip-light.css"; }) "${cfgHome}/gtk-3.0/gtk.css"}

    # System color-scheme. GTK applications (and Firefox content processes
    # via xdg-desktop-portal-gtk) read this to determine prefers-color-scheme.
    ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme "${if isDark then "prefer-dark" else "prefer-light"}"
    ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme "${if isDark then palette.gtk.dark_name else palette.gtk.light_name}"
    ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/gtk-application-prefer-dark-theme "${if isDark then "true" else "false"}"
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

  xdg.dataFile."icons/hicolor/scalable/apps/darkman.svg".source = ./icons/darkman.svg;
}
