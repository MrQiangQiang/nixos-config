{
  config,
  lib,
  pkgs,
  ...
}:

let
  isDesktopEnabled = config.custom.desktop.enable;
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
    # ClassicUI theme: system-level config via /etc/xdg/fcitx5/conf/classicui.conf.
    # Home Manager's xdg.configFile uses linkFarm (read-only nix store symlink
    # directory) which prevents fcitx5's safeSave() from writing runtime config.
    # System-level config via /etc/xdg/ avoids this — fcitx5 reads it reliably
    # through StandardPaths::PkgConfig search (User > System priority).
    # Theme directory names (rose-pine-dark/light) are the contract with
    # fcitx5.nix which deploys the actual theme files to ~/.local/share/fcitx5/themes/.
    fcitx5.settings.addons = {
      classicui.globalSection = {
        Theme = "rose-pine-light";
        DarkTheme = "rose-pine-dark";
        UseDarkTheme = "True";
      };
    };
  };

  environment.variables.QT_IM_MODULE = "fcitx";

  environment.systemPackages = with pkgs; [
    qt6Packages.fcitx5-configtool
    (runCommand "fcitx5-configtool-icon" { } ''
      mkdir -p $out/share/icons/hicolor/scalable/apps
      ln -s ${papirus-icon-theme}/share/icons/Papirus/48x48/devices/input-keyboard.svg \
        $out/share/icons/hicolor/scalable/apps/input-keyboard.svg
    '')
  ];
}
