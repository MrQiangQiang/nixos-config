{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      maplemono-nf-cn
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "Maple Mono NF CN" "Noto Sans Mono CJK SC" ];
        sansSerif = [ "Noto Sans CJK SC" "DejaVu Sans" ];
        serif = [ "Noto Serif CJK SC" "DejaVu Serif" ];
      };
    };
  };
}
