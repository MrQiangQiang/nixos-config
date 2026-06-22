# helix — modal text editor (Layer 0: auto-follows terminal via OSC 11)
#
# Architecture:
#   foot terminal → OSC 11 → helix auto-selects theme-dark/theme-light
#   TTY (no OSC 11) → uses dark theme (no auto-switch, but TTY is rare)
#
# Theme names from palette.helix (single source), colors from palette.dark/dawn.
# No darkman entry needed — helix follows the terminal, like bat/fish/starship.
# No template file needed — helix themes are pure TOML, generated inline as Nix attrsets.
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

  mkHelixTheme = c: {
    # --- UI ---
    "ui.background" = {
      bg = c.base;
    };
    "ui.cursor" = {
      fg = c.text;
      bg = c.text;
      modifiers = [ "reversed" ];
    };
    "ui.cursor.insert" = {
      fg = c.text;
      bg = c.text;
    };
    "ui.cursor.select" = {
      fg = c.base;
      bg = c.iris;
    };
    "ui.cursor.match" = {
      fg = c.base;
      bg = c.foam;
    };
    "ui.cursor.primary" = {
      fg = c.base;
      bg = c.iris;
    };
    "ui.linenr" = {
      fg = c.muted;
    };
    "ui.linenr.selected" = {
      fg = c.text;
      modifiers = [ "bold" ];
    };
    "ui.linenr.relative" = {
      fg = c.muted;
    };
    "ui.selection" = {
      bg = c.highlight_med;
    };
    "ui.selection.primary" = {
      bg = c.highlight_high;
    };
    "ui.text" = {
      fg = c.text;
    };
    "ui.text.focus" = {
      fg = c.text;
    };
    "ui.text.inactive" = {
      fg = c.subtle;
    };
    "ui.menu" = {
      bg = c.surface;
      fg = c.text;
    };
    "ui.menu.selected" = {
      bg = c.highlight_med;
      fg = c.text;
    };
    "ui.popup" = {
      bg = c.surface;
    };
    "ui.popup.info" = {
      fg = c.foam;
    };
    "ui.window" = {
      bg = c.base;
    };
    "ui.help" = {
      bg = c.surface;
      fg = c.text;
    };
    "ui.statusline" = {
      bg = c.overlay;
      fg = c.subtle;
    };
    "ui.statusline.insert" = {
      bg = c.pine;
      fg = c.base;
    };
    "ui.statusline.select" = {
      bg = c.iris;
      fg = c.base;
    };
    "ui.statusline.normal" = {
      bg = c.overlay;
      fg = c.text;
    };
    "ui.statusline.inactive" = {
      bg = c.base;
      fg = c.muted;
    };
    "ui.statusline.separator" = {
      fg = c.muted;
    };
    "ui.bufferline" = {
      bg = c.overlay;
      fg = c.subtle;
    };
    "ui.bufferline.active" = {
      bg = c.surface;
      fg = c.text;
    };
    "ui.virtual.inlay-hint" = {
      bg = c.highlight_low;
      fg = c.muted;
    };
    "ui.virtual.ruler" = {
      bg = c.highlight_low;
    };
    "ui.virtual.whitespace" = {
      fg = c.highlight_med;
    };
    "ui.gutter" = {
      bg = c.base;
    };
    "ui.highlight" = {
      bg = c.highlight_med;
    };
    "ui.debug" = {
      fg = c.love;
    };

    # --- syntax ---
    "comment" = {
      fg = c.muted;
      modifiers = [ "italic" ];
    };
    "variable" = {
      fg = c.text;
    };
    "variable.builtin" = {
      fg = c.iris;
    };
    "variable.parameter" = {
      fg = c.text;
    };
    "constant" = {
      fg = c.iris;
    };
    "constant.numeric" = {
      fg = c.iris;
    };
    "type" = {
      fg = c.foam;
    };
    "type.builtin" = {
      fg = c.foam;
    };
    "function" = {
      fg = c.rose;
    };
    "function.method" = {
      fg = c.rose;
    };
    "function.macro" = {
      fg = c.rose;
    };
    "keyword" = {
      fg = c.pine;
    };
    "keyword.directive" = {
      fg = c.pine;
    };
    "keyword.function" = {
      fg = c.pine;
    };
    "keyword.operator" = {
      fg = c.pine;
    };
    "operator" = {
      fg = c.subtle;
    };
    "string" = {
      fg = c.gold;
    };
    "string.special" = {
      fg = c.gold;
    };
    "namespace" = {
      fg = c.rose;
    };
    "module" = {
      fg = c.rose;
    };
    "attribute" = {
      fg = c.foam;
    };
    "property" = {
      fg = c.foam;
    };
    "constructor" = {
      fg = c.foam;
    };
    "label" = {
      fg = c.pine;
    };
    "tag" = {
      fg = c.love;
    };

    # --- markup ---
    "markup.heading" = {
      fg = c.rose;
      modifiers = [ "bold" ];
    };
    "markup.list" = {
      fg = c.foam;
    };
    "markup.bold" = {
      modifiers = [ "bold" ];
    };
    "markup.italic" = {
      modifiers = [ "italic" ];
    };
    "markup.link.url" = {
      fg = c.foam;
      modifiers = [ "underlined" ];
    };
    "markup.link.text" = {
      fg = c.rose;
    };
    "markup.quote" = {
      fg = c.gold;
    };
    "markup.raw" = {
      fg = c.text;
    };

    # --- diff ---
    "diff.plus" = {
      fg = c.foam;
    };
    "diff.delta" = {
      fg = c.gold;
    };
    "diff.minus" = {
      fg = c.love;
    };

    # --- diagnostic ---
    "diagnostic" = {
      modifiers = [ "underlined" ];
    };
    "warning" = {
      fg = c.gold;
    };
    "error" = {
      fg = c.love;
    };
    "info" = {
      fg = c.foam;
    };
    "hint" = {
      fg = c.iris;
    };
  };

  darkThemeName = palette.helix.dark;
  lightThemeName = palette.helix.light;
in
lib.mkIf isDesktopEnabled {
  programs.helix = {
    enable = true;

    extraPackages = with pkgs; [
      nil
    ];

    settings = {
      theme = darkThemeName;

      editor = {
        line-number = "relative";
        cursor-shape = {
          normal = "block";
          insert = "bar";
          select = "underline";
        };
        lsp.display-messages = true;
        auto-save = {
          focus-lost = true;
        };
        soft-wrap.enable = false;
        true-color = true;
        color-modes = true;
      };

      keys.normal = {
        esc = [
          "collapse_selection"
          "keep_primary_selection"
        ];
        space.space = "file_picker";
        space.w = ":w";
        space.q = ":q";
      };

      keys.insert = {
        "C-s" = ":w";
      };
    };

    languages = {
      language-server.nil = {
        command = "${lib.getExe pkgs.nil}";
      };

      language = [
        {
          name = "nix";
          auto-format = true;
          formatter = {
            command = "${lib.getExe pkgs.nixfmt}";
          };
          language-servers = [ "nil" ];
        }
      ];
    };

    themes = {
      ${darkThemeName} = mkHelixTheme palette.dark;
      ${lightThemeName} = mkHelixTheme palette.dawn;
    };
  };

}
