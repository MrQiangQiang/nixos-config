{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  cfgHome = config.xdg.configHome;

  cp = source: target: ''
    mkdir -p $(${pkgs.coreutils}/bin/dirname ${target})
    rm -f ${target}
    ${pkgs.coreutils}/bin/cp ${source} ${target}
  '';

  signal = sig: cmd: ''
    if ${pkgs.procps}/bin/pgrep -x ${cmd} >/dev/null 2>&1; then
      ${pkgs.coreutils}/bin/kill -${sig} $(${pkgs.procps}/bin/pgrep -x ${cmd})
    fi
  '';

  applyTheme = mode: let
    isDark = mode == "dark";
    src = { dark ? null, light ? null }: if isDark then config.xdg.configFile.${dark}.source
                                          else config.xdg.configFile.${light}.source;
  in ''
    ${cp (src { dark = "theme/kwm-config-dark.zon"; light = "theme/kwm-config-light.zon"; }) "${cfgHome}/kwm/config.zon"}
    ${signal "SIGUSR1" "kwm"}

    ${cp (src { dark = "theme/mako-config-dark"; light = "theme/mako-config-light"; }) "${cfgHome}/mako/config"}
    ${pkgs.mako}/bin/makoctl reload 2>/dev/null || true

    ${cp (src { dark = "theme/fuzzel-config-dark.ini"; light = "theme/fuzzel-config-light.ini"; }) "${cfgHome}/fuzzel/fuzzel.ini"}

    ${cp (src { dark = "theme/wob-config-dark.ini"; light = "theme/wob-config-light.ini"; }) "${cfgHome}/wob/wob.ini"}
    systemctl --user restart wob 2>/dev/null || true

    ${cp (src { dark = "theme/foot-dark.ini"; light = "theme/foot-light.ini"; }) "${cfgHome}/foot/foot.ini"}
    ${signal (if isDark then "SIGUSR1" else "SIGUSR2") "foot"}

    ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/gtk-theme "'${if isDark then palette.gtk.dark_name else palette.gtk.light_name}'"
    ${pkgs.dconf}/bin/dconf write /org/gnome/desktop/interface/color-scheme "'${if isDark then "prefer-dark" else "prefer-light"}'"
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
}
