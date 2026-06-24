# Obsidian — markdown knowledge base browser (Karpathy LLM Wiki pattern)
#
# Architecture:
#   - Obsidian desktop app (overridden pkgs.obsidian with bootstrap.cjs injected)
#     Bootstrap: reads darkman mode → sets nativeTheme.themeSource → Obsidian's
#     nativeTheme.on("updated") listener triggers theme switch (same pattern as
#     trae-cn). No darkman entry needed — bootstrap self-handles.
#   - Rose Pine theme: official theme deployed per-vault + CSS snippet override
#     (Variable-First: official theme provides CSS structure using var(--rp-*),
#     snippet provides color values from palette.nix respecting dark_variant).
#     Snippet lists all variant classes (.theme-dark.rose-norm/.rose-moon) to
#     match official specificity (0,2,0); loads after theme.css → wins.
#     Snippet overrides THREE layers of variables:
#     1. --rp-* palette (15 vars) — dark_variant resolution (main/moon)
#     2. --rp-accent, --rp-highlight — @settings defaults not in CSS without
#        Style Settings plugin (accent=iris CSS fallback, highlight=undefined)
#     3. --accent-h/s/l, --text-highlight-bg-rgb — Obsidian BASE accent vars
#        not overridden by official theme.css. Without these, --color-accent
#        stays purple (h=258), affecting tags, focus rings, active-hover, etc.
#   - appearance.json: theme="system" + cssTheme="Rose Pine" + snippet enabled.
#     Merged with existing settings via jq (preserves user customizations).
#   - Vault at ~/knowledge/ — git-cloned on all hosts via repos.nix
#   - Obsidian config (.obsidian/) — runtime-managed, NOT home-managed
#     (workspace.json/cache change frequently; symlinking would break)
#   - Community plugins — managed by obsidian-plugins.nix (declarative, per-vault)
#
# Installed on ALL hosts (desktop-1 + laptop-1):
#   - desktop-1: agent-side browsing, graph view inspection
#   - laptop-1: primary human browsing interface
#
# Web Clipper (browser extension) is configured in firefox.nix via policies.
{ pkgs, config, lib, palette, ... }:
let
  vaultPath = "${config.home.homeDirectory}/knowledge";

  # Official Rose Pine theme (manifest.json + theme.css).
  # No release tags — pinned to commit e2b47ad (v0.1.19).
  rosePineTheme = pkgs.fetchFromGitHub {
    owner = "rose-pine";
    repo = "obsidian";
    rev = "e2b47ad4ff24626b597d0b2a36250e22073760e7";
    hash = "sha256-HSGFmmQcH2WlJBpPv2yek16iiz92leQbIspCN6oB1AA=";
  };

  # CSS snippet: overrides --rp-* variables with palette.nix colors.
  # 15 variables × 2 variants (dark/light). dark_variant (main/moon) is
  # resolved at compile time via palette.dark — snippet always has the
  # correct dark variant, no runtime class switching needed.
  mkSnippetVars = suffix: c:
    builtins.listToAttrs (builtins.map (name: {
      name = "${name}_${suffix}";
      value = c.${name};
    }) [
      "base" "surface" "overlay" "muted" "subtle" "text"
      "love" "gold" "rose" "pine" "foam" "iris"
      "highlight_low" "highlight_med" "highlight_high"
      "accent_h" "accent_s" "accent_l" "highlight_rgb"
    ]);

  snippetVars = mkSnippetVars "dark" palette.dark // mkSnippetVars "light" palette.dawn;
  rosePineSnippet = pkgs.replaceVars ./rose-pine-obsidian.css snippetVars;
in
{
  home.packages = [ pkgs.obsidian ];

  # Deploy Rose Pine theme + CSS snippet + appearance settings per-vault.
  # Uses activation script (not home.file) because .obsidian/ is runtime-managed
  # — workspace.json/cache change frequently, symlinking would break.
  home.activation.obsidianTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Deploy official Rose Pine theme (manifest.json + theme.css)
    THEME_DIR="${vaultPath}/.obsidian/themes/Rose Pine"
    mkdir -p "$THEME_DIR"
    cp -f ${rosePineTheme}/manifest.json "$THEME_DIR/"
    cp -f ${rosePineTheme}/theme.css "$THEME_DIR/"

    # Deploy CSS snippet (palette.nix colors via replaceVars)
    SNIPPET_DIR="${vaultPath}/.obsidian/snippets"
    mkdir -p "$SNIPPET_DIR"
    cp -f ${rosePineSnippet} "$SNIPPET_DIR/rose-pine-obsidian.css"

    # Update appearance.json — merge declared settings with existing
    APPEARANCE="${vaultPath}/.obsidian/appearance.json"
    mkdir -p "$(dirname "$APPEARANCE")"
    existing=$(cat "$APPEARANCE" 2>/dev/null || echo "{}")
    # Guard against empty/invalid JSON (file exists but empty, or corrupted)
    echo "$existing" | ${pkgs.jq}/bin/jq empty 2>/dev/null || existing="{}"
    echo "$existing" | ${pkgs.jq}/bin/jq -c \
      --arg theme "system" \
      --arg cssTheme "Rose Pine" \
      --argjson snippets '["rose-pine-obsidian"]' \
      '. + {theme: $theme, cssTheme: $cssTheme, enabledCssSnippets: ($snippets + (.enabledCssSnippets // []) | unique)}' \
      > "$APPEARANCE"
  '';
}
