# lazygit — terminal git UI (Layer 0: ANSI auto-follows terminal palette)
#
# Theme from official rose-pine/lazygit (commit acc968a, 2025-11-05).
# Uses ANSI color names via palette.ansi so colors auto-follow darkman:
#   foot terminal sets ANSI 16-color palette based on dark/dawn mode.
#   lazygit reads ANSI names → foot resolves to Rose Pine hex → auto-switches.
#   This is the same layer as starship/fish (ANSI auto-follow, no darkman entry).
#
# Two colors keep static hex (no ANSI slot in palette.ansi):
#   - inactiveBorderColor (muted): medium gray, readable on both dark/light bg
#   - cherryPickedCommitFgColor (surface): dark text on rose bg, readable on both
#
# Runtime switching: new lazygit processes correct after darkman toggle.
# Running instances may not redraw (persistent TUI, like yazi).
{
  palette,
  ...
}:

let
  a = palette.ansi;
  c = palette.dark;
in
{
  programs.lazygit = {
    enable = true;
    settings = {
      gui.theme = {
        activeBorderColor = [
          a.pine
          "bold"
        ];
        inactiveBorderColor = [ "#${c.muted}" ];
        searchingActiveBorderColor = [
          a.rose
          "bold"
        ];
        optionsTextColor = [ a.foam ];
        selectedLineBgColor = [ a.pine ];
        inactiveViewSelectedLineBgColor = [
          a.overlay
          "bold"
        ];
        cherryPickedCommitFgColor = [ "#${c.surface}" ];
        cherryPickedCommitBgColor = [ a.rose ];
        markedBaseCommitFgColor = [ a.foam ];
        markedBaseCommitBgColor = [ a.gold ];
        unstagedChangesColor = [ a.love ];
        defaultFgColor = [ "default" ];
      };
    };
  };
}
