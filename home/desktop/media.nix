# mpd — music playback daemon
# mpdris2 — MPRIS bridge (→ existing media-keys.nix works via playerctl)
# beets — music library metadata manager (desktop-1 only, canonical source)
# mpv — video player (Wayland native via gpu-next)
# mpc/rmpc/yt-dlp — CLI tools + TUI client
#
# Component responsibilities (Unix pipeline):
#   yazi → mpc CLI → mpd daemon → pipewire → speakers
#   yazi → mpv → wayland window
#   beets → metadata tags in files → mpd tag_cache
#
# Host-specific:
#   desktop-1: full stack (beets enabled, /data/annex/music)
#   laptop-1:  playback only (~/annex/music, git-annex partial checkout)
{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  isDesktop1 = osConfig.networking.hostName == "desktop-1";
  musicDir = if isDesktop1 then "/data/annex/music" else "/home/fugui/annex/music";
in
lib.mkIf isDesktopEnabled {
  services.mpd = {
    enable = true;
    musicDirectory = musicDir;
    extraConfig = ''
      bind_to_address  "${config.services.mpd.dataDir}/socket"
      audio_output {
        type  "pipewire"
        name  "PipeWire"
      }
    '';
  };

  systemd.user.services.mpd = {
    Unit.X-Restart-Triggers = [
      "${pkgs.writeText "mpd-config-hash" config.services.mpd.generatedConfig}"
    ];
  };

  services.mpdris2 = {
    enable = true;
    notifications = true;
    multimediaKeys = true;
  };

  programs.beets = lib.mkIf isDesktop1 {
    enable = true;
    settings = {
      directory = musicDir;
      plugins = [
        "lastgenre"
        "autobpm"
        "smartplaylist"
        "fetchart"
        "replaygain"
        "fromfilename"
      ];
    };
    mpdIntegration = {
      enableStats = true;
      enableUpdate = true;
    };
  };

  programs.mpv = {
    enable = true;
    config = {
      vo = "gpu-next";
      hwdec = "auto-safe";
    };
  };

  home.packages = with pkgs; [
    mpc
    rmpc
    yt-dlp
    python3Packages.mpv
    python3Packages.mpd2
  ];
}
