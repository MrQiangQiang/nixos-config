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
#
# Theme deployment — TWO paths:
#   1. Main vault (~/knowledge/): activation script deploys theme files directly
#      to .obsidian/themes/ + .obsidian/snippets/ + appearance.json.
#      Uses activation script (not home.file) because .obsidian/ is runtime-managed
#      (workspace.json/cache change frequently; symlinking would break).
#   2. Sandbox vault (~/.config/obsidian/Obsidian Sandbox/): theme files are baked
#      into the sandbox template inside obsidian.asar at package build time via
#      overrideAttrs below. Obsidian's p() function DELETES and RECREATES the
#      sandbox directory from this template every time Help → Sandbox is clicked.
#      Because the template includes .obsidian/ (appearance.json + theme + snippet),
#      theme files are copied automatically — no runtime deployment, no race.
#
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
{
  pkgs,
  config,
  lib,
  palette,
  ...
}:
let
  # Main vault — git-cloned on all hosts via repos.nix (always exists).
  # Sandbox vault is NOT listed here — its theme is baked into obsidian.asar
  # at package build time (see overrideAttrs below).
  vaults = [
    "${config.home.homeDirectory}/knowledge"
  ];

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
  mkSnippetVars =
    suffix: c:
    builtins.listToAttrs (
      builtins.map
        (name: {
          name = "${name}_${suffix}";
          value = c.${name};
        })
        [
          "base"
          "surface"
          "overlay"
          "muted"
          "subtle"
          "text"
          "love"
          "gold"
          "rose"
          "pine"
          "foam"
          "iris"
          "highlight_low"
          "highlight_med"
          "highlight_high"
          "accent_h"
          "accent_s"
          "accent_l"
          "highlight_rgb"
        ]
    );

  snippetVars = mkSnippetVars "dark" palette.dark // mkSnippetVars "light" palette.dawn;
  rosePineSnippet = pkgs.replaceVars ./rose-pine-obsidian.css snippetVars;

  # Starter screen CSS (vault switcher + version info modal).
  # starter.html hardcodes <body class="theme-dark"> and only loads app.css —
  # vault-level theme.css/snippets are NOT loaded. bootstrap.cjs reads this
  # file and injects via webContents.insertCSS() on the starter window.
  # Deployed to ~/.config/obsidian/ (global, pre-vault) not vault-level.
  #
  # Separate var set (not snippetVars) because replaceVars requires every
  # provided key to appear in the template — starter.css only uses base/
  # surface/overlay/muted/subtle/text + accent_h/s/l, not the full palette.
  mkStarterVars =
    suffix: c:
    builtins.listToAttrs (
      builtins.map
        (name: {
          name = "${name}_${suffix}";
          value = c.${name};
        })
        [
          "base"
          "surface"
          "overlay"
          "muted"
          "subtle"
          "text"
          "accent_h"
          "accent_s"
          "accent_l"
        ]
    );
  starterVars = mkStarterVars "dark" palette.dark // mkStarterVars "light" palette.dawn;
  rosePineStarterCSS = pkgs.replaceVars ./rose-pine-obsidian-starter.css starterVars;
in
{
  # Override pkgs.obsidian (already has bootstrap.cjs injected via overlay) to
  # also bake Rose Pine theme files into the sandbox template inside obsidian.asar.
  # This ensures the sandbox vault always has the correct theme, even though
  # Obsidian's p() function deletes and recreates the directory on every open.
  # Theme files come from the same rosePineTheme/rosePineSnippet sources used
  # for the main vault — single source of truth, palette.nix colors included.
  home.packages = [
    (pkgs.obsidian.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        cd $out/share/obsidian
        asar extract obsidian.asar obs-src
        mkdir -p 'obs-src/sandbox/.obsidian/themes/Rose Pine'
        mkdir -p 'obs-src/sandbox/.obsidian/snippets'
        cp ${rosePineTheme}/manifest.json 'obs-src/sandbox/.obsidian/themes/Rose Pine/'
        cp ${rosePineTheme}/theme.css 'obs-src/sandbox/.obsidian/themes/Rose Pine/'
        cp ${rosePineSnippet} 'obs-src/sandbox/.obsidian/snippets/rose-pine-obsidian.css'
        echo '{"theme":"system","cssTheme":"Rose Pine","enabledCssSnippets":["rose-pine-obsidian"]}' \
          > 'obs-src/sandbox/.obsidian/appearance.json'
        rm -f obsidian.asar
        asar pack obs-src obsidian.asar
        rm -rf obs-src
      '';
    }))
  ];

  # Deploy Rose Pine theme + CSS snippet + appearance settings to main vault.
  # Uses activation script (not home.file) because .obsidian/ is runtime-managed
  # — workspace.json/cache change frequently, symlinking would break.
  # Sandbox vault is handled at package build time (see overrideAttrs above).
  home.activation.obsidianTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Deploy starter screen CSS (global, pre-vault — bootstrap.cjs injects it)
    STARTER_DIR="${config.home.homeDirectory}/.config/obsidian"
    mkdir -p "$STARTER_DIR"
    cp -f ${rosePineStarterCSS} "$STARTER_DIR/starter.css"

    # Per-vault theme deployment (function avoids duplication across vaults).
    deploy_vault_theme() {
      local vault_path="$1"
      [ -d "$vault_path" ] || return 0

      # Deploy official Rose Pine theme (manifest.json + theme.css)
      local theme_dir="$vault_path/.obsidian/themes/Rose Pine"
      mkdir -p "$theme_dir"
      cp -f ${rosePineTheme}/manifest.json "$theme_dir/"
      cp -f ${rosePineTheme}/theme.css "$theme_dir/"

      # Deploy CSS snippet (palette.nix colors via replaceVars)
      local snippet_dir="$vault_path/.obsidian/snippets"
      mkdir -p "$snippet_dir"
      cp -f ${rosePineSnippet} "$snippet_dir/rose-pine-obsidian.css"

      # Update appearance.json — merge declared settings with existing
      local appearance="$vault_path/.obsidian/appearance.json"
      mkdir -p "$(dirname "$appearance")"
      local existing
      existing=$(cat "$appearance" 2>/dev/null || echo "{}")
      # Guard against empty/invalid JSON (file exists but empty, or corrupted)
      echo "$existing" | ${pkgs.jq}/bin/jq empty 2>/dev/null || existing="{}"
      echo "$existing" | ${pkgs.jq}/bin/jq -c \
        --arg theme "system" \
        --arg cssTheme "Rose Pine" \
        --argjson snippets '["rose-pine-obsidian"]' \
        '. + {theme: $theme, cssTheme: $cssTheme, enabledCssSnippets: ($snippets + (.enabledCssSnippets // []) | unique)}' \
        > "$appearance"
    }

    ${lib.concatMapStrings (v: ''
      deploy_vault_theme "${v}"
    '') vaults}
  '';
}
