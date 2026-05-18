{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName = "fugui";
    userEmail = "chenzhiqiang0125@gamil.com";
  };

  programs.vim = {
    enable = true;
    extraConfig = ''
      set number
      syntax on
    '';
  };

  home.packages = with pkgs; [ 
    fastfetch
    htop
  ];
}
