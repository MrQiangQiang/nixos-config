# bat — syntax-highlighted file viewer (Layer 0: auto-follows terminal via OSC 11)
#
# Architecture:
#   foot terminal → OSC 11 → bat auto-selects theme-dark/theme-light
#   TTY (no OSC 11) → bat_tty_theme fish function sets BAT_THEME env
#
# Theme names from palette.bat (single source), colors from palette.dark/dawn
# via replaceVars on rose-pine-bat.tmTheme (same pattern as kwm-config.zon).
#
# No darkman entry needed — bat follows the terminal, like fish/starship.
# No cat alias — bat is for interactive viewing, cat is for scripting.
{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;

  mkBatThemeVars = c: {
    inherit (c) base surface muted subtle text love gold rose pine foam iris;
    highlight_med = c.highlight_med;
  };

  darkVars = mkBatThemeVars palette.dark // {
    name = if palette.dark_variant == "moon" then "Rosé Pine Moon" else "Rosé Pine";
  };
  dawnVars = mkBatThemeVars palette.dawn // { name = "Rosé Pine Dawn"; };

  darkTheme = pkgs.replaceVars ./rose-pine-bat.tmTheme darkVars;
  dawnTheme = pkgs.replaceVars ./rose-pine-bat.tmTheme dawnVars;

  darkThemeName = palette.bat.dark;
  lightThemeName = palette.bat.light;
in
lib.mkIf isDesktopEnabled {
  programs.bat = {
    enable = true;
    themes = {
      ${darkThemeName} = { src = darkTheme; };
      ${lightThemeName} = { src = dawnTheme; };
    };
    config = {
      italic-text = "always";
      theme-dark = darkThemeName;
      theme-light = lightThemeName;
    };
  };

  # TTY fallback: bat cannot detect dark/light via OSC 11 in Linux console.
  # Set BAT_THEME env var on every prompt so bat uses the correct Rose Pine
  # variant. Self-contained — removing bat.nix from imports removes this
  # function with zero cleanup in fish.nix.
  programs.fish.functions.bat_tty_theme = {
    body = ''
      if test "$TERM" = "linux"
        set -l _mode (cat ~/.cache/darkman/mode.txt 2>/dev/null; or echo dark)
        if test "$_mode" = "dark"
          set -gx BAT_THEME ${darkThemeName}
        else
          set -gx BAT_THEME ${lightThemeName}
        end
      end
    '';
    onEvent = "fish_prompt";
  };

  home.sessionVariables = {
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    MANROFFOPT = "-c";
  };
}
