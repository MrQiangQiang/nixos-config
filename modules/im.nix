{ config, lib, pkgs, ... }:

let
  isDesktopEnabled = config.custom.desktop.enable or false;
in
lib.mkIf isDesktopEnabled {
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      qt6Packages.fcitx5-chinese-addons
      fcitx5-gtk
      qt6Packages.fcitx5-qt
    ];
  };

  environment.systemPackages = with pkgs; [
    qt6Packages.fcitx5-configtool
  ];
}
