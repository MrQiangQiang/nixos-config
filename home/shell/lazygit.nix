# lazygit — terminal git UI (static dark theme; running instances don't switch)
#
# Theme from official rose-pine/lazygit (commit acc968a, 2025-11-05).
# Hex colors mapped to palette.dark fields (auto-resolves main/moon via dark_variant).
#
# Runtime switching limitation (same as yazi):
#   lazygit is a persistent TUI — running instances do NOT switch on darkman toggle.
#   New instances inherit the static dark theme below.
# This is acceptable: git operations are short-session.
#
# No darkman entry — would conflict with home-manager's config.yml symlink.
# To support switching, would need to drop programs.lazygit.settings and use
# xdg.configFile + darkman link (like kwm/foot). Not worth the complexity for a
# short-session TUI — static dark matches the official repo's pick-once model.
{
  palette,
  ...
}:

let
  c = palette.dark;
in
{
  programs.lazygit = {
    enable = true;
    settings = {
      gui.theme = {
        activeBorderColor = [
          "#${c.pine}"
          "bold"
        ];
        inactiveBorderColor = [ "#${c.muted}" ];
        searchingActiveBorderColor = [
          "#${c.rose}"
          "bold"
        ];
        optionsTextColor = [ "#${c.foam}" ];
        selectedLineBgColor = [ "#${c.pine}" ];
        inactiveViewSelectedLineBgColor = [
          "#${c.overlay}"
          "bold"
        ];
        cherryPickedCommitFgColor = [ "#${c.surface}" ];
        cherryPickedCommitBgColor = [ "#${c.rose}" ];
        markedBaseCommitFgColor = [ "#${c.foam}" ];
        markedBaseCommitBgColor = [ "#${c.gold}" ];
        unstagedChangesColor = [ "#${c.love}" ];
        defaultFgColor = [ "#${c.text}" ];
      };
    };
  };
}
