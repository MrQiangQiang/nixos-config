{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  d = palette.dark;
  l = palette.dawn;
  cfgHome = config.xdg.configHome;

  darkMako = pkgs.writeText "mako-config-dark" ''
    font=monospace 12
    background-color=#${d.base}ff
    text-color=#${d.text}ff
    border-color=#${d.pine}ff
    border-size=2
    default-timeout=5000
  '';

  lightMako = pkgs.writeText "mako-config-light" ''
    font=monospace 12
    background-color=#${l.base}ff
    text-color=#${l.text}ff
    border-color=#${l.pine}ff
    border-size=2
    default-timeout=5000
  '';

  darkFuzzel = pkgs.writeText "fuzzel-config-dark.ini" ''
    [main]
    font=monospace:size=12
    prompt=> 
    dpi-aware=auto

    [colors]
    background=${d.base}ff
    text=${d.text}ff
    match=${d.pine}ff
    selection=${d.pine}ff
    selection-text=${d.text}ff
  '';

  lightFuzzel = pkgs.writeText "fuzzel-config-light.ini" ''
    [main]
    font=monospace:size=12
    prompt=> 
    dpi-aware=auto

    [colors]
    background=${l.base}ff
    text=${l.text}ff
    match=${l.pine}ff
    selection=${l.pine}ff
    selection-text=${l.text}ff
  '';

  darkWob = pkgs.writeText "wob-config-dark.ini" ''
    timeout=1000
    anchor=top right
    margin=10
    padding=5
    border_size=2
    bar_padding=5
    background_color=${d.base}ff
    bar_color=${d.pine}ff
    border_color=${d.pine}ff
  '';

  lightWob = pkgs.writeText "wob-config-light.ini" ''
    timeout=1000
    anchor=top right
    margin=10
    padding=5
    border_size=2
    bar_padding=5
    background_color=${l.base}ff
    bar_color=${l.pine}ff
    border_color=${l.pine}ff
  '';

  darkFoot = pkgs.writeText "foot-config-dark.ini" ''
    [main]
    font=monospace:size=16

    [colors]
    foreground=${d.text}ff
    background=${d.base}ff
    regular0=${d.overlay}ff
    regular1=${d.love}ff
    regular2=${d.pine}ff
    regular3=${d.gold}ff
    regular4=${d.foam}ff
    regular5=${d.iris}ff
    regular6=${d.rose}ff
    regular7=${d.text}ff
    bright0=${d.muted}ff
    bright1=${d.love}ff
    bright2=${d.pine}ff
    bright3=${d.gold}ff
    bright4=${d.foam}ff
    bright5=${d.iris}ff
    bright6=${d.rose}ff
    bright7=${d.text}ff
  '';

  lightFoot = pkgs.writeText "foot-config-light.ini" ''
    [main]
    font=monospace:size=16

    [colors]
    foreground=${l.text}ff
    background=${l.base}ff
    regular0=${l.overlay}ff
    regular1=${l.love}ff
    regular2=${l.pine}ff
    regular3=${l.gold}ff
    regular4=${l.foam}ff
    regular5=${l.iris}ff
    regular6=${l.rose}ff
    regular7=${l.text}ff
    bright0=${l.muted}ff
    bright1=${l.love}ff
    bright2=${l.pine}ff
    bright3=${l.gold}ff
    bright4=${l.foam}ff
    bright5=${l.iris}ff
    bright6=${l.rose}ff
    bright7=${l.text}ff
  '';

  kwmReload = ''
    if pgrep -x kwm &>/dev/null && pgrep -x ydotoold &>/dev/null; then
      ${pkgs.ydotool}/bin/ydotool key 125:1 42:1 19:1 19:0 42:0 125:0
    fi
  '';

  applyTheme = mode: let
    isDark = mode == "dark";
    kwmSource = if isDark then config.xdg.configFile."kwm/config.zon".source
                else config.xdg.configFile."theme/kwm-config-light.zon".source;
    makoSource = if isDark then darkMako else lightMako;
    fuzzelSource = if isDark then darkFuzzel else lightFuzzel;
    wobSource = if isDark then darkWob else lightWob;
    footSource = if isDark then darkFoot else lightFoot;
    gtkName = if isDark then palette.gtk.dark_name else palette.gtk.light_name;
    colorScheme = if isDark then "prefer-dark" else "prefer-light";
  in ''
    ${pkgs.coreutils}/bin/cp -f ${kwmSource} ${cfgHome}/kwm/config.zon
    ${kwmReload}

    ${pkgs.coreutils}/bin/cp -f ${makoSource} ${cfgHome}/mako/config
    ${pkgs.mako}/bin/makoctl reload 2>/dev/null || true

    ${pkgs.coreutils}/bin/cp -f ${fuzzelSource} ${cfgHome}/fuzzel/fuzzel.ini

    ${pkgs.coreutils}/bin/cp -f ${wobSource} ${cfgHome}/wob/wob.ini

    ${pkgs.coreutils}/bin/cp -f ${footSource} ${cfgHome}/foot/foot.ini

    ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme '${gtkName}'
    ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme '${colorScheme}'
  '';
in
lib.mkIf isDesktopEnabled {
  services.darkman = {
    enable = true;
    darkModeScripts.dark-theme = applyTheme "dark";
    lightModeScripts.light-theme = applyTheme "light";
  };

  xdg.configFile."darkman/config.yaml".text = ''
    lat: 31.2
    long: 121.5
  '';
}
