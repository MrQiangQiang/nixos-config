# mpv — video player (Wayland native via gpu-next)
# uosc — modern OSC with semantic color model (10 fields) for Rose Pine mapping.
# thumbfast — on-the-fly thumbnailer, uosc auto-detects via script-message.
# OSD/subtitle/letterbox colors fixed to dark palette (video matte should always
# be dark, consistent with uosc curtain — light letterbox is jarring on bright scenes).
# mpv reads config at startup only (no watcher) — short-session mode, ln -sf is enough.
{
  config,
  lib,
  pkgs,
  osConfig,
  palette,
  ...
}:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  d = palette.dark; # fixed dark for OSD/subtitle/curtain/letterbox
  l = palette.dawn; # light variant for uosc

  # uosc color format: key=rrggbb (no #), comma-separated.
  # curtain fixed to dark base (video matte should always be dark).
  # timeline_style=bar: filled bar instead of default 2px line.
  mkUoscConfig = colors: ''
    timeline_style=bar
    color=foreground=${colors.subtle},foreground_text=${colors.base},background=${colors.surface},background_text=${colors.text},window_border=${colors.highlight_high},curtain=${d.base},success=${colors.foam},error=${colors.love},match=${colors.iris},heatmap=${colors.pine}
    chapter_ranges=openings:${colors.iris}64,endings:${colors.iris}64,ads:${colors.love}80
  '';
in
lib.mkIf isDesktopEnabled {
  programs.mpv = {
    enable = true;
    scripts = [
      pkgs.mpvScripts.uosc
      pkgs.mpvScripts.thumbfast
    ];
    config = {
      vo = "gpu-next";
      # hwdec=auto: zero-copy vaapi (decode frames stay on GPU).
      # auto-safe forces vaapi-copy (GPU→CPU→GPU round-trip per frame),
      # devastating for 4K HEVC on Skylake (12.4MB/frame copy overhead).
      hwdec = "auto";
      osc = "no"; # disable native OSC, uosc takes over
      osd-bar = "no"; # uosc provides its own seek/volume indicators
      border = "no"; # uosc draws window controls
      # letterbox/background: fixed dark base (same as curtain/OSD/subtitle).
      # Video matte should always be dark regardless of darkman mode.
      background = "color";
      background-color = "#${d.base}";
      # OSD/subtitle fixed dark (readable on any video background)
      osd-color = "#${d.text}";
      osd-border-color = "#${d.base}";
      osd-back-color = "#${d.base}";
      sub-color = "#${d.text}";
      sub-border-color = "#${d.base}";
      sub-back-color = "#${d.base}";
    };
  };

  xdg.configFile."theme/uosc-dark.conf" = {
    source = pkgs.writeText "uosc-dark.conf" (mkUoscConfig d);
  };
  xdg.configFile."theme/uosc-light.conf" = {
    source = pkgs.writeText "uosc-light.conf" (mkUoscConfig l);
  };
}
