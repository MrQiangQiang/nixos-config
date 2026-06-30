# fzf — fuzzy finder (Layer 0: FZF_DEFAULT_OPTS via fish prompt hook)
#
# Architecture:
#   bash → programs.fzf.defaultOptions (static dark)
#   fish → fzf_theme function on fish_prompt → dynamic FZF_DEFAULT_OPTS
#   Next fzf invocation (CTRL-R/CTRL-T/ALT-C) reads current FZF_DEFAULT_OPTS
#
# Real-time switching: YES in fish (new fzf process reads env var set by hook).
# Static dark in bash (bash is login shell, execs to fish immediately).
#
# Hex colors from palette.nix via official rose-pine/fzf mapping (2025-11-05).
# No darkman entry — fish prompt hook handles switching (fzf has no OSC 11).
{
  lib,
  palette,
  ...
}:

let
  mkFzfOpts = c: [
    "--color=fg:#${c.subtle},bg:#${c.base},hl:#${c.rose}"
    "--color=fg+:#${c.text},bg+:#${c.overlay},hl+:#${c.rose}"
    "--color=border:#${c.highlight_med},header:#${c.pine},gutter:#${c.base}"
    "--color=spinner:#${c.gold},info:#${c.foam}"
    "--color=pointer:#${c.iris},marker:#${c.love},prompt:#${c.subtle}"
  ];

  darkOpts = mkFzfOpts palette.dark;
  lightOpts = mkFzfOpts palette.dawn;

  darkOptsStr = lib.concatStringsSep " " darkOpts;
  lightOptsStr = lib.concatStringsSep " " lightOpts;
in
{
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    # Static dark for bash; fish overrides via fzf_theme function
    defaultOptions = darkOpts;
  };

  # Dynamic FZF_DEFAULT_OPTS based on darkman mode (fish only).
  # Reads ~/.cache/darkman/mode.txt on every prompt (negligible overhead).
  # Defaults to dark if darkman not available (headless hosts).
  programs.fish.functions.fzf_theme = {
    body = ''
      set -l _mode (cat ~/.cache/darkman/mode.txt 2>/dev/null; or echo dark)
      if test "$_mode" = "dark"
        set -gx FZF_DEFAULT_OPTS "${darkOptsStr}"
      else
        set -gx FZF_DEFAULT_OPTS "${lightOptsStr}"
      end
    '';
    onEvent = "fish_prompt";
  };
}
