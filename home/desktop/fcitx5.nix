{ config, lib, pkgs, osConfig, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
in
lib.mkIf isDesktopEnabled {
  xdg.configFile."fcitx5/conf/notifications.conf" = {
    force = true;
    text = ''
      HiddenNotifications=wayland-diagnostic-gtk-im-module,wayland-diagnostic-qt-im-module
    '';
  };
}
