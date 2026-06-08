{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  d = palette.dark;
  l = palette.dawn;

  # Fish 4.3+ Auto theme: [dark]/[light] sections auto-selected by terminal
  # background color via OSC 11. When darkman switches foot's color scheme,
  # Fish re-evaluates and applies the matching section automatically.
  mkFishThemeSection = c: ''
    fish_color_normal ${c.text}
    fish_color_command ${c.iris}
    fish_color_keyword ${c.foam}
    fish_color_quote ${c.gold}
    fish_color_redirection ${c.pine}
    fish_color_end ${c.subtle}
    fish_color_error ${c.love}
    fish_color_param ${c.rose}
    fish_color_comment ${c.subtle}
    fish_color_selection --reverse
    fish_color_operator ${c.text}
    fish_color_escape ${c.pine}
    fish_color_autosuggestion ${c.subtle}
    fish_color_cwd ${c.rose}
    fish_color_user ${c.gold}
    fish_color_host ${c.foam}
    fish_color_host_remote ${c.iris}
    fish_color_cancel ${c.text}
    fish_color_search_match --background=${c.base}
    fish_color_valid_path

    fish_pager_color_progress ${c.rose}
    fish_pager_color_background --background=${c.surface}
    fish_pager_color_prefix ${c.foam}
    fish_pager_color_completion ${c.subtle}
    fish_pager_color_description ${c.subtle}
    fish_pager_color_secondary_background
    fish_pager_color_secondary_prefix
    fish_pager_color_secondary_completion
    fish_pager_color_secondary_description
    fish_pager_color_selected_background --background=${c.overlay}
    fish_pager_color_selected_prefix ${c.foam}
    fish_pager_color_selected_completion ${c.text}
    fish_pager_color_selected_description ${c.text}

    fish_color_subtle ${c.subtle}
    fish_color_text ${c.text}
    fish_color_love ${c.love}
    fish_color_gold ${c.gold}
    fish_color_rose ${c.rose}
    fish_color_pine ${c.pine}
    fish_color_foam ${c.foam}
    fish_color_iris ${c.iris}
    fish_color_base ${c.base}
  '';

  # TTY fallback: ANSI names that map to Rose Pine semantics through the
  # foot-aligned TTY 16-color palette (set by console.colors / mkTtyEscapes).
  # This section is mode-agnostic — when mkTtyEscapes applies dawn palette,
  # ANSI names automatically resolve to dawn colors.
  #
  # Foot-aligned ANSI → Rose Pine mapping:
  #   black=overlay red=love green=foam yellow=gold
  #   blue=pine magenta=iris cyan=rose white=text brblack=muted
  ttyThemeSection = ''
    fish_color_normal white
    fish_color_command magenta
    fish_color_keyword green
    fish_color_quote yellow
    fish_color_redirection blue
    fish_color_end brblack
    fish_color_error red
    fish_color_param cyan
    fish_color_comment brblack
    fish_color_selection --reverse
    fish_color_operator white
    fish_color_escape blue
    fish_color_autosuggestion brblack
    fish_color_cwd cyan
    fish_color_user yellow
    fish_color_host green
    fish_color_host_remote magenta
    fish_color_cancel white
    fish_color_search_match --background=black
    fish_color_valid_path

    fish_pager_color_progress cyan
    fish_pager_color_background --background=black
    fish_pager_color_prefix green
    fish_pager_color_completion brblack
    fish_pager_color_description brblack
    fish_pager_color_secondary_background
    fish_pager_color_secondary_prefix
    fish_pager_color_secondary_completion
    fish_pager_color_secondary_description
    fish_pager_color_selected_background --background=black
    fish_pager_color_selected_prefix green
    fish_pager_color_selected_completion white
    fish_pager_color_selected_description white
  '';

  themeContent = "[unknown]\n${ttyThemeSection}\n\n[dark]\n${mkFishThemeSection d}\n\n[light]\n${mkFishThemeSection l}";
  # Apply TTY palette escape sequences for the given mode (fish syntax).
  # Used by tty_theme_sync for runtime palette changes.
  # Escape strings from palette.nix (single source).
  applyTtyPalette = mode: ''
      if test "${mode}" = "light"
          printf '${palette.tty.light}'
      else
          printf '${palette.tty.dark}'
      end
  '';
in
lib.mkIf isDesktopEnabled {
  programs.fish = {
    enable = true;
    shellInit = ''
      set -g fish_greeting
    '';
    interactiveShellInit = ''
      if test "$TERM" = "linux"
          # Inherit TTY theme mode from bash login shell (set in profileExtra).
          # Falls back to reading mode.txt if not set (e.g. fish as login shell).
          if set -q __tty_theme_mode
          else
              set -g __tty_theme_mode (cat ~/.cache/darkman/mode.txt 2>/dev/null; or echo dark)
          end
      end
      fish_config theme choose Rose-Pine-Auto
    '';

    # Re-apply TTY palette when darkman mode changes between prompts.
    # Runs once per prompt display — zero cost when mode unchanged (one file read).
    # fbcon renders characters as pixels in the framebuffer; palette changes via
    # \033]Pn update the hardware cmap but do NOT re-render existing pixels.
    # `clear` is essential to force a full-screen redraw with the new palette.
    functions.tty_theme_sync = {
      body = ''
          if test "$TERM" = "linux"
              set -l _mode (cat ~/.cache/darkman/mode.txt 2>/dev/null; or echo dark)
              if test "$_mode" != "$__tty_theme_mode"
                  set -g __tty_theme_mode $_mode
                  ${applyTtyPalette "$_mode"}
                  clear
              end
          end
      '';
      onEvent = "fish_prompt";
    };
  };

  xdg.configFile."fish/themes/Rose-Pine-Auto.theme".source =
    pkgs.writeText "Rose-Pine-Auto.theme" themeContent;
}
