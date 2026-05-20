{ config, lib, pkgs, ... }: {
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      fcitx5-chinese-addons
      fcitx5-gtk
      fcitx5-qt
    ];
  };

  environment.variables = with pkgs; {
    GTK_IM_MODULE = lib.mkForce "fcitx5";
    QT_IM_MODULE = lib.mkForce "fcitx5";
    XMODIFIERS = lib.mkForce "@im=fcitx";
  };

  environment.systemPackages = with pkgs; [
    fcitx5-configtool
  ];

  services.xserver.desktopManager.runXdgAutostartIfNone = true;
}
