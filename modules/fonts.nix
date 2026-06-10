{ pkgs, ... }:{
  fonts = {
    packages = with pkgs; [
      maple-mono.NF-CN
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "Maple Mono NF CN" "Noto Sans Mono CJK SC" ];
        sansSerif = [ "Noto Sans CJK SC" "DejaVu Sans" "Maple Mono NF CN" ];
        serif = [ "Noto Serif CJK SC" "DejaVu Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
