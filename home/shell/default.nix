{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "fugui";
        email = "chenzhiqiang0125@gmail.com";
      };
    };
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
