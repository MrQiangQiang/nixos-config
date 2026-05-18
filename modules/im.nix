{
  config,
  pkgs,
  ...
}:

{  
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [ qt6Packages.fcitx5-chinese-addons ];
  };

  environment.variables = with pkgs; {
    GTK_IM_MODULE = "fcitx5";
    QT_IM_MODULE = "fcitx5";
    XMODIFIERS = "@im=fcitx5";
  };

  environment.systemPackages = with pkgs; [
    qt6Packages.fcitx5-configtool
  ];

  services.xserver.desktopManager.runXdgAutostartIfNone = true;
}
