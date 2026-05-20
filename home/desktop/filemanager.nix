{ config, lib, pkgs, osConfig, ... }:
let
  isRiverEnabled = osConfig.custom.river.enable or false;
in
lib.mkIf isRiverEnabled {
  programs.yazi = {
    enable = true;
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
}
