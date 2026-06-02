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

  environment.variables.QT_IM_MODULE = "fcitx";

  environment.systemPackages = with pkgs; [
    qt6Packages.fcitx5-configtool
    (runCommand "fcitx5-configtool-icon" {} ''
      mkdir -p $out/share/icons/hicolor/scalable/apps
      ln -s ${papirus-icon-theme}/share/icons/Papirus/48x48/devices/input-keyboard.svg \
        $out/share/icons/hicolor/scalable/apps/input-keyboard.svg
    '')
  ];
}
