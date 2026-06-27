# Obsidian community plugins — declarative installation via Nix
#
# Architecture:
#   - Obsidian plugins are PER-VAULT (not global). Each vault has its own
#     .obsidian/plugins/ directory and .obsidian/community-plugins.json
#   - This file declares plugins per vault. Add new vaults to the `vaults` list.
#   - Plugin files (main.js, manifest.json, styles.css) are downloaded at build
#     time via fetchurl (hash-locked, reproducible) and deployed at activation
#     time (home-manager switch).
#
# Adding a new plugin:
#   1. Find plugin's GitHub repo and latest release tag
#   2. Get file hashes (run for each file: main.js, manifest.json, styles.css):
#        nix-prefetch-url https://github.com/<owner>/<repo>/releases/download/<version>/<file>
#   3. Convert to SRI: nix hash to-sri --type sha256 <hash>
#   4. Add entry to the vault's `plugins` list (see dataview example below)
#
# Updating a plugin:
#   1. Check latest release tag on GitHub
#   2. Re-run nix-prefetch-url for each file (hash changes with version)
#   3. Update `version` and `hashes` in the list below
#   4. Run: nixos-rebuild switch (or home-manager switch)
#
# Future: a `update-obsidian-plugins.sh` script could automate steps 1-3
#         using GitHub API (semi-automatic, not fully auto due to Nix hash locking).
{
  pkgs,
  config,
  lib,
  ...
}:
let
  # Vault definitions — each vault has a path and a list of plugins
  # Plugins are per-vault (Obsidian design: .obsidian/ is per-vault)
  vaults = [
    {
      path = "${config.home.homeDirectory}/knowledge";
      plugins = [
        {
          id = "dataview";
          owner = "blacksmithgu";
          repo = "obsidian-dataview";
          version = "0.5.70";
          hashes = {
            mainJs = "sha256-a7HPcBCvrYMOc1dfyg4r+9MnnFYuPZ0k8tL0UWHrfQA=";
            manifest = "sha256-kjXbRxEtqBuFWRx57LmuJXTl5yIHBW6XZHL5BhYoYYU=";
            styles = "sha256-MwbdkDLgD5ibpyM6N/0lW8TT9DQM7mYXYulS8/aqHek=";
          };
        }
      ];
    }
    # Future vaults example:
    # {
    #   path = "${config.home.homeDirectory}/other-vault";
    #   plugins = [
    #     { id = "dataview"; owner = "blacksmithgu"; repo = "obsidian-dataview";
    #       version = "0.5.70"; hashes = { ... }; }
    #     { id = "obsidian-marp"; owner = "alangrainger"; repo = "obsidian-marp";
    #       version = "0.1.0"; hashes = { ... }; }
    #   ];
    # }
  ];

  # Download a single plugin file via fetchurl (hash-locked, reproducible)
  fetchFile = url: sha256: pkgs.fetchurl { inherit url sha256; };

  # Assemble plugin directory from 3 release files
  fetchPlugin =
    {
      id,
      owner,
      repo,
      version,
      hashes,
    }:
    pkgs.runCommand "obsidian-plugin-${id}-${version}" { } ''
      mkdir $out
      cp ${fetchFile "https://github.com/${owner}/${repo}/releases/download/${version}/main.js" hashes.mainJs} $out/main.js
      cp ${fetchFile "https://github.com/${owner}/${repo}/releases/download/${version}/manifest.json" hashes.manifest} $out/manifest.json
      cp ${fetchFile "https://github.com/${owner}/${repo}/releases/download/${version}/styles.css" hashes.styles} $out/styles.css
    '';

  # Deploy plugins to a vault — returns bash script string
  deployVaultPlugins =
    { path, plugins }:
    let
      pluginDirs = builtins.map (p: {
        id = p.id;
        src = fetchPlugin p;
      }) plugins;
      pluginIds = builtins.map (p: p.id) plugins;
      pluginIdsJson = builtins.toJSON pluginIds;
    in
    ''
      # Deploy plugins to ${path}
      PLUGINS_DIR="${path}/.obsidian/plugins"
      mkdir -p "$PLUGINS_DIR"

      ${lib.concatMapStrings (p: ''
        # Deploy plugin: ${p.id}
        mkdir -p "$PLUGINS_DIR/${p.id}"
        cp -f ${p.src}/main.js "$PLUGINS_DIR/${p.id}/"
        cp -f ${p.src}/manifest.json "$PLUGINS_DIR/${p.id}/"
        cp -f ${p.src}/styles.css "$PLUGINS_DIR/${p.id}/"
      '') pluginDirs}

      # Update community-plugins.json (merge declared plugins with existing)
      COMMUNITY_PLUGINS="${path}/.obsidian/community-plugins.json"
      mkdir -p "$(dirname "$COMMUNITY_PLUGINS")"
      existing=$(cat "$COMMUNITY_PLUGINS" 2>/dev/null || echo "[]")
      echo "$existing" | ${pkgs.jq}/bin/jq -c --argjson plugins '${pluginIdsJson}' '. + $plugins | unique' > "$COMMUNITY_PLUGINS"
    '';
in
{
  home.activation.obsidianPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${lib.concatMapStrings deployVaultPlugins vaults}
  '';
}
