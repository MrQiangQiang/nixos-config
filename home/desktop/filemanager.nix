{ config, lib, pkgs, osConfig, ... }:
let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
in
lib.mkIf isDesktopEnabled {
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    settings = {
      manager = {
        sort_by = "natural";
        sort_sensitive = true;
        sort_dir_first = true;
        show_hidden = true;
        show_symlink = false;
        ratio = [ 1 3 4 ];
        linemode = "size";
        scrolloff = 5;
      };
    };
  };
  

  home.packages = with pkgs; [
    thunar
    tumbler
    gvfs
    ffmpegthumbnailer
    poppler-utils
    unrar
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "thunar.desktop" ];
    };
  };

  xdg.dataFile."icons/hicolor/scalable/apps/yazi.svg".source = ./icons/yazi.svg;
}
