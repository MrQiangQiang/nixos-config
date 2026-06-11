{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  d = palette.dark;
  l = palette.dawn;

  # Build theme as a derivation with REAL files (not nix store symlinks).
  # fcitx5's StandardPaths::open() handles symlinks but real files eliminate
  # any potential edge cases with gdk-pixbuf image loading through symlink chains.
  #
  # No PNG assets: radio.png/arrow.png are only used by XCBMenu (system tray
  # right-click menu). Our Wayland + KWM environment has no system tray, so
  # XCBMenu is never triggered (waylandui.cpp has zero menu code). Even if
  # triggered, fcitx5 falls back to solid-color rectangles (theme.cpp:327).
  mkFcitx5ThemeDerivation = variantName: colors:
    pkgs.runCommand "fcitx5-theme-${variantName}" {
      themeConf = pkgs.writeText "theme.conf" (mkFcitx5Theme colors);
    } ''
      mkdir $out
      cp $themeConf $out/theme.conf
    '';

  mkFcitx5Theme = colors: ''
    # vim: ft=dosini
    [Metadata]
    Name=Rosé Pine
    Version=1
    Author=rose-pine
    Description=All natural pine, faux fur and a bit of soho vibes for the classy minimalist
    ScaleWithDPI=True

    [InputPanel]
    Font=Sans 13
    NormalColor=#${colors.subtle}
    HighlightCandidateColor=#${colors.text}
    HighlightColor=#${colors.text}
    HighlightBackgroundColor=#${colors.overlay}
    Spacing=3

    [InputPanel/TextMargin]
    Left=10
    Right=10
    Top=6
    Bottom=6

    [InputPanel/Background]
    Color=#${colors.overlay}

    [InputPanel/Background/Margin]
    Left=2
    Right=2
    Top=2
    Bottom=2

    [InputPanel/Highlight]
    Color=#${colors.highlight_med}

    [InputPanel/Highlight/Margin]
    Left=10
    Right=10
    Top=7
    Bottom=7
  '';
in
lib.mkIf isDesktopEnabled {
  # Deploy themes to XDG_DATA_HOME/fcitx5/themes/ — fcitx5's StandardPaths
  # looks for themes there. Two fixed directories (rose-pine-dark, rose-pine-light)
  # instead of one symlinked "current" directory.
  xdg.dataFile."fcitx5/themes/rose-pine-dark".source = mkFcitx5ThemeDerivation "dark" d;
  xdg.dataFile."fcitx5/themes/rose-pine-light".source = mkFcitx5ThemeDerivation "light" l;

  # classicui theme is configured at system level via i18n.inputMethod.fcitx5.settings.addons
  # in modules/im.nix, writing to /etc/xdg/fcitx5/conf/classicui.conf. fcitx5 reads this
  # reliably via StandardPaths PkgConfig search. User-level xdg.configFile uses linkFarm
  # (read-only nix store symlink directory) which breaks fcitx5's safeSave() write-and-rename
  # pattern — the config content is correct but runtime persistence fails.

  # Make profile declarative: keyboard-us + pinyin in Default group.
  # Ensures Ctrl+Space toggles between English and Chinese input.
  xdg.configFile."fcitx5/profile".text = ''
    [Groups/0]
    # Group Name
    Name=Default
    # Layout
    Default Layout=us
    # Default Input Method
    DefaultIM=keyboard-us

    [Groups/0/Items/0]
    # Name
    Name=keyboard-us
    # Layout
    Layout=

    [Groups/0/Items/1]
    # Name
    Name=pinyin
    # Layout
    Layout=us

    [GroupOrder]
    0=Default
  '';
}