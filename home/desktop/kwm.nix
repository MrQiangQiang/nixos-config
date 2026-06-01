{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  d = palette.dark;
  l = palette.dawn;
  darkZON = pkgs.replaceVars ./config/kwm-config.zon {
    inherit (d) base text pine surface muted love;
  };
  lightZON = pkgs.replaceVars ./config/kwm-config.zon {
    inherit (l) base text pine surface muted love;
  };
in
lib.mkIf isDesktopEnabled {
  home.packages = with pkgs; [
    kwm
    kwim
    (writeShellScriptBin "polkit-gnome-authentication-agent-1" ''
      exec ${polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 "$@"
    '')
    (writeShellScriptBin "screenshot-region" ''
      region=$(${slurp}/bin/slurp)
      ${grim}/bin/grim -g "$region" - | ${wl-clipboard}/bin/wl-copy
    '')
  ];

  xdg.configFile."kwm/config.zon" = {
    source = darkZON;
    onChange = ''
      mode=$(${pkgs.darkman}/bin/darkman get 2>/dev/null || echo "dark")
      ${pkgs.darkman}/bin/darkman set "$mode"
    '';
  };

  xdg.configFile."theme/kwm-config-light.zon".source = lightZON;
}
