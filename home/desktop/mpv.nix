# mpv — video player (Wayland native via gpu-next)
# uosc — modern OSC with semantic color model (10 fields) for Rose Pine mapping.
# thumbfast — on-the-fly thumbnailer, uosc auto-detects via script-message.
# OSD/subtitle colors fixed to dark palette (video background varies; light
# outlines unreadable on bright scenes). uosc curtain also fixed dark.
# mpv reads config at startup only (no watcher) — short-session mode, ln -sf is enough.
# background-color follows darkman via include=~~/theme-colors.conf (ln -sf switched).
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
  d = palette.dark; # fixed dark for OSD/subtitle/curtain
  l = palette.dawn; # light variant for uosc + mpv background

  # uosc color format: key=rrggbb (no #), comma-separated.
  # curtain fixed to dark base (video matte should always be dark).
  # timeline_style=bar: filled bar instead of default 2px line.
  mkUoscConfig = colors: ''
    timeline_style=bar
    color=foreground=${colors.subtle},foreground_text=${colors.base},background=${colors.surface},background_text=${colors.text},window_border=${colors.highlight_high},curtain=${d.base},success=${colors.foam},error=${colors.love},match=${colors.iris},heatmap=${colors.pine}
    chapter_ranges=openings:${colors.iris}64,endings:${colors.iris}64,ads:${colors.love}80
  '';

  # mpv background-color: letterbox region color, follows darkman.
  # Included via programs.mpv.includes (~~/theme-colors.conf → ln -sf by darkman).
  mkMpvColors = colors: ''
    background-color=#${colors.base}
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
      hwdec = "auto-safe";
      # Skylake HD 530 lacks HEVC/VP9/AV1 VA-API; software decode uses 4 threads
      # (i5-6300HQ 4c/4t) to avoid CPU saturation on H265 content.
      vd-lavc-threads = 4;
      osc = "no"; # disable native OSC, uosc takes over
      osd-bar = "no"; # uosc provides its own seek/volume indicators
      border = "no"; # uosc draws window controls
      # letterbox as solid color (color itself from include=~~/theme-colors.conf)
      background = "color";
      # OSD/subtitle fixed dark (readable on any video background)
      osd-color = "#${d.text}";
      osd-border-color = "#${d.base}";
      osd-back-color = "#${d.base}";
      sub-color = "#${d.text}";
      sub-border-color = "#${d.base}";
      sub-back-color = "#${d.base}";
    };
    # theme-colors.conf is symlinked by darkman (dark/light variant).
    # ~~ expands to mpv config dir (~/.config/mpv/).
    includes = [ "~~/theme-colors.conf" ];
  };

  xdg.configFile."theme/uosc-dark.conf" = {
    source = pkgs.writeText "uosc-dark.conf" (mkUoscConfig d);
  };
  xdg.configFile."theme/uosc-light.conf" = {
    source = pkgs.writeText "uosc-light.conf" (mkUoscConfig l);
  };
  xdg.configFile."theme/mpv-colors-dark.conf" = {
    source = pkgs.writeText "mpv-colors-dark.conf" (mkMpvColors d);
  };
  xdg.configFile."theme/mpv-colors-light.conf" = {
    source = pkgs.writeText "mpv-colors-light.conf" (mkMpvColors l);
  };
}
