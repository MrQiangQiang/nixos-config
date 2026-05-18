{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = [ "Noto Sans CJK SC" "DejaVu Sans" ];
        serif = [ "Noto Serif CJK SC" "DejaVu Serif" ];
        monospace = [ "Noto Sans Moon CJK SC" "DejaVu Sans Mono" ];
      };
    };
  };
}
