# rmpc — MPD TUI client
# Rose Pine theme via palette.nix (dark/light) + darkman ln -sf + IPC broadcast.
# config_watcher only accepts Close(Write) events, so ln -sf alone won't switch
# the theme at runtime — darkman also runs `rmpc remote set theme <path>` to
# broadcast ThemeChanged to all running instances via /tmp/rmpc-*.sock.
#
# Theme fields not listed here (layout, components, song_table_format, etc.)
# use rmpc defaults. Their ANSI color names (yellow/blue/red/green/...) are
# resolved by foot terminal via palette.ansi, so most components already match
# Rose Pine without explicit overrides.
#
# Patches (against upstream v0.11.0):
#   fix-playlist-empty.patch — allow creating playlists with no songs selected
#   fix-ime-cursor.patch — position terminal cursor for fcitx5 IME anchoring
#   zh-cn-descriptions.patch — translate keybind descriptions to Chinese
#   zxcv-icons-and-styles.patch — zxcv → Nerd Font icons (󰑖󰒝󰈸󰑘); removes
#     decorative [] (icons are self-explanatory); adds trailing space in labels
#     for icon spacing; on/off/oneshot styles: green+Bold / gray+Dim / yellow+Bold
#     (off uses gray not dark_gray — dark_gray maps to bright_overlay #fffdf5,
#     invisible on dawn base #faf4ed; gray maps to text, visible in both themes);
#     volume slider track_style blue+Dim. Touches defaults.rs +
#     assets/example_theme.ron (test example_theme_equals_default requires sync).
{
  config,
  lib,
  pkgs,
  osConfig,
  palette,
  ...
}:

let
  isDesktopEnabled = osConfig.custom.desktop.enable;
  d = palette.dark;
  l = palette.dawn;

  mkRmpcTheme = colors: ''
    #![enable(implicit_some)]
    #![enable(unwrap_newtypes)]
    #![enable(unwrap_variant_newtypes)]
    (
        background_color: "#${colors.base}",
        text_color: "#${colors.text}",
        modal_background_color: "#${colors.surface}",
        modal_backdrop: false,
        preview_label_style: (fg: "#${colors.gold}"),
        preview_metadata_group_style: (fg: "#${colors.gold}", modifiers: "Bold"),
        highlighted_item_style: (fg: "#${colors.pine}", modifiers: "Bold"),
        current_item_style: (fg: "#${colors.base}", bg: "#${colors.pine}", modifiers: "Bold"),
        borders_style: (fg: "#${colors.highlight_high}"),
        highlight_border_style: (fg: "#${colors.rose}"),
        symbols: (
            song: "S",
            dir: "D",
            playlist: "P",
            marker: "M",
            ellipsis: "...",
            song_style: (fg: "#${colors.foam}"),
            dir_style: (fg: "#${colors.gold}"),
            playlist_style: (fg: "#${colors.rose}"),
        ),
        level_styles: (
            info: (fg: "#${colors.foam}"),
            warn: (fg: "#${colors.gold}"),
            error: (fg: "#${colors.love}"),
            debug: (fg: "#${colors.pine}"),
            trace: (fg: "#${colors.iris}"),
        ),
        progress_bar: (
            symbols: ["█", "█", "█", " ", "█"],
            track_style: (fg: "#${colors.highlight_med}"),
            elapsed_style: (fg: "#${colors.pine}"),
            thumb_style: (fg: "#${colors.pine}"),
            use_track_when_empty: true,
        ),
        scrollbar: (
            symbols: ["│", "█", "▲", "▼"],
            track_style: (fg: "#${colors.highlight_med}"),
            ends_style: (fg: "#${colors.subtle}"),
            thumb_style: (fg: "#${colors.subtle}"),
        ),
        tab_bar: (
            active_style: (fg: "#${colors.base}", bg: "#${colors.pine}", modifiers: "Bold"),
            inactive_style: (),
        ),
        lyrics: (
            timestamp: false,
        ),
        cava: (
            bg_color: "#${colors.base}",
            bar_color: Gradient({
                0: "#${colors.pine}",
                100: "#${colors.foam}",
            }),
        ),
    )
  '';
in
lib.mkIf isDesktopEnabled {
  programs.rmpc = {
    enable = true;
    package = pkgs.rmpc.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        ./rmpc/fix-playlist-empty.patch
        ./rmpc/fix-ime-cursor.patch
        ./rmpc/zh-cn-descriptions.patch
        ./rmpc/zxcv-icons-and-styles.patch
      ];
    });
    config = ''
      (
          address: "${config.services.mpd.dataDir}/socket",
          lyrics_dir: Some("${config.services.mpd.musicDirectory}"),
          theme: Some("rose-pine"),
      )
    '';
  };

  xdg.configFile."theme/rmpc-dark.ron" = {
    source = pkgs.writeText "rmpc-dark.ron" (mkRmpcTheme d);
  };
  xdg.configFile."theme/rmpc-light.ron" = {
    source = pkgs.writeText "rmpc-light.ron" (mkRmpcTheme l);
  };
}
