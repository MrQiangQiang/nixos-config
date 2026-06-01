{ config, lib, pkgs, osConfig, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
in
lib.mkIf isDesktopEnabled {
  home.packages = with pkgs; [
    grim
    slurp
    (writeShellScriptBin "screenshot-region" ''
      region=$(${slurp}/bin/slurp)
      ${grim}/bin/grim -g "$region" - | ${wl-clipboard}/bin/wl-copy
    '')
  ];
}
