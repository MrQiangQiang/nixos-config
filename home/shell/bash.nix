# Login shell is bash (POSIX-compatible) for remote tool compatibility
# (VS Code Remote SSH, ansible, etc.). Interactive sessions auto-transition
# to fish. Do NOT set `shell = pkgs.fish` — it breaks non-interactive SSH.
#
# Login layer: apply TTY palette from darkman state before exec fish.
# This ensures correct colors immediately after login, independent of which
# interactive shell is used. Runtime sync is handled by fish tty_theme_sync.
{
  lib,
  osConfig,
  palette,
  ...
}:

let
  isDesktopEnabled = osConfig.custom.desktop.enable;
in
{
  programs.bash = {
    enable = true;
    profileExtra = lib.mkIf isDesktopEnabled ''
      if [ "$TERM" = "linux" ]; then
          _tty_mode=$(cat ~/.cache/darkman/mode.txt 2>/dev/null || echo dark)
          if [ "$_tty_mode" = "light" ]; then
              printf '${palette.tty.light}'
          else
              printf '${palette.tty.dark}'
          fi
          export __tty_theme_mode="$_tty_mode"
          clear
      fi
    '';
    initExtra = ''
      if [[ -z "''${BASH_EXECUTION_STRING:-}" ]] && command -v fish &>/dev/null; then
        exec fish
      fi
    '';
  };
}
