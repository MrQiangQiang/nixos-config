# mpd — music playback daemon
# mpdris2 — MPRIS bridge (→ existing media-keys.nix works via playerctl)
# beets — music library metadata manager (desktop-1 only, canonical source)
# mpv — video player (Wayland native via gpu-next)
# mpc/rmpc/yt-dlp — CLI tools + TUI client
# alx — agent-lx-music CLI downloader (desktop-1 only, domestic platforms)
# music-sync — one-shot sync script: git add/commit + beet update + mpc update
#
# Component responsibilities (Unix pipeline):
#   alx → /data/annex/music (audio+embedded cover via annex, .lrc via git)
#   music-sync → git commit + beet update (DB only, no move) + mpc update
#   yazi → mpc CLI → mpd daemon → pipewire → speakers
#   yazi → mpv → wayland window
#   beets → metadata tags in files → mpd tag_cache
#
# Host-specific:
#   desktop-1: full stack (beets + alx + music-sync, /data/annex/music)
#   laptop-1:  playback only (~/annex/music, git-annex partial checkout)
{
  config,
  lib,
  pkgs,
  inputs,
  osConfig,
  ...
}:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  isDesktop1 = osConfig.networking.hostName == "desktop-1";
  musicDir = if isDesktop1 then "/data/annex/music" else "/home/fugui/annex/music";

  # alx upstream flake.nix omits clang from nativeBuildInputs, but rquickjs-sys
  # uses bindgen which requires libclang.so + glibc headers (stdio.h etc.).
  # overrideAttrs patches the upstream derivation instead of forking.
  alxPkg =
    inputs.agent-lx-music.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
      (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
          pkgs.llvmPackages.libclang
          pkgs.llvmPackages.clang
        ];
        LIBCLANG_PATH = "${lib.getLib pkgs.llvmPackages.libclang}/lib";
        BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${lib.getDev pkgs.glibc}/include";
      });

  # One-shot sync after alx downloads:
  #   - git annex add . : .lrc tracked by git (.gitattributes), audio by annex
  #   - git commit : persist metadata (.lrc content + annex pointer)
  #   - beet import -q -A -M -W : import new files (skip existing) without
  #     autotag/move/write — alx already embedded metadata+cover
  #   - mpc update --wait : rescan mpd tag_cache and wait for completion
  music-sync = pkgs.writeShellScriptBin "music-sync" ''
    set -e
    cd /data/annex
    git annex add .
    git commit -m "chore(music): sync $(date -Iseconds)" || echo "nothing to commit"
    beet import -q -A -M -W music/
    mpc update --wait
  '';
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

  # beets: metadata DB only.
  # import.move/copy=false: alx writes files directly to /data/annex/music,
  #   beets must NOT relocate them (path mismatch with .lrc would break rmpc).
  # group_albums=true: group by tag (Album+AlbumArtist), not directory —
  #   handles alx's flat output structure.
  # fetchart removed: alx already embeds cover into tags (rmpc uses EmbeddedFirst).
  programs.beets = lib.mkIf isDesktop1 {
    enable = true;
    settings = {
      directory = musicDir;
      plugins = [
        "lastgenre"
        "autobpm"
        "smartplaylist"
        "fromfilename"
      ];
      import = {
        move = false;
        copy = false;
        group_albums = true;
      };
    };
    mpdIntegration = {
      enableStats = true;
      enableUpdate = true;
    };
  };

  # rmpc: lyrics_dir mirrors song_file path (flat → flat).
  # album_art.order = EmbeddedFirst (default): alx embeds cover into tags,
  #   no external cover.jpg needed.
  programs.rmpc = {
    enable = true;
    config = ''
      (
          address: "${config.services.mpd.dataDir}/socket",
          lyrics_dir: Some("${musicDir}"),
      )
    '';
  };

  programs.mpv = {
    enable = true;
    config = {
      vo = "gpu-next";
      hwdec = "auto-safe";
    };
  };

  # alx config (desktop-1 only):
  #   output_dir = /data/annex/music (write directly into annex repo)
  #   embed_cover = true    (cover in tag, rmpc EmbeddedFirst)
  #   save_lyrics_file = true   (.lrc alongside audio, rmpc reads it)
  #   embed_lyrics = false  (avoid redundancy — rmpc only reads .lrc)
  #   save_cover_file = false   (no n+1 external cover files)
  #   beet_import = false   (use music-sync instead, alx's beet import is --copy)
  xdg.configFile."agent-lx-music/config.toml" = lib.mkIf isDesktop1 {
    text = ''
      [source]
      default_source = "all"
      default_quality = "320k"
      quality_fallback = ["320k", "128k", "flac"]
      js_priority = true
      priority = ["_4", "_9.393DeepSeek"]
      platform_priority = ["wy", "kw", "tx", "mg", "kg"]

      [player]
      default_volume = 80
      repeat = "off"
      shuffle = false
      mpv_args = []
      enable_mpris = true
      auto_resume = true

      [download]
      output_dir = "${musicDir}"
      filename_template = "{singer} - {title}"
      embed_metadata = true
      embed_lyrics = false
      embed_lyrics_lx = true
      embed_lyrics_translated = false
      embed_lyrics_romanized = false
      embed_cover = true
      save_lyrics_file = true
      save_cover_file = false
      lrc_encoding = "utf8"
      max_concurrent = 3
      skip_existing = true
      use_other_source = true
      group_by_source = false
      timeout = 60
      beet_import = false
      use_beets_library = false

      [history]
      max_age_days = 90

      [display]
      color = "auto"
      table_style = "rounded"
      show_progress = true

      [network]
      timeout = 15
      max_retries = 2
    '';
  };

  home.packages =
    with pkgs;
    [
      mpc
      yt-dlp
      python3Packages.mpv
      python3Packages.mpd2
    ]
    ++ lib.optionals isDesktop1 [
      alxPkg
      music-sync
    ];
}
