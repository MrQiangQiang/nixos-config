# tealdeer — fast tldr client in Rust (13ms vs Node tldr 407ms)
# No theme — output follows terminal ANSI palette.
# home-manager's enableAutoUpdates (default true) provides a systemd timer;
# tealdeer's built-in auto_update left at default (false) to avoid duplication.
{ programs.tealdeer.enable = true; }
