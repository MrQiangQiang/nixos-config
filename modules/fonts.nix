{ pkgs, ... }:{
  fonts = {
    packages = with pkgs; [
      maple-mono.NF-CN
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      noto-fonts
    ];

    fontconfig = {
      enable = true;
      localConf = ''
        <alias>
          <family>Maple Mono NF CN</family>
          <default><family>Noto Sans Symbols 2</family></default>
        </alias>
      '';
      defaultFonts = {
        monospace = [ "Maple Mono NF CN" "Noto Sans Mono CJK SC" ];
        sansSerif = [ "Noto Sans CJK SC" "DejaVu Sans" "Maple Mono NF CN" ];
        serif = [ "Noto Serif CJK SC" "DejaVu Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
