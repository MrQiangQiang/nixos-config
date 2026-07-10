{
  config,
  lib,
  pkgs,
  osConfig,
  keybinds,
  ...
}:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;

  formatMods = mods: lib.concatStringsSep "+" mods;

  tierTag = tier: if tier == "managed" then "M" else "D";

  # Format: "key  desc(alias)  tag  app  category"
  # Key first for fastest search, alias for English keyword search
  formatBinding =
    app: tier: b:
    let
      tag = tierTag tier;
      modStr = formatMods b.mods;
      keyStr = if modStr == "" then b.key else "${modStr}+${b.key}";
      modeStr = lib.optionalString (b.mode or null != null) " [${b.mode}]";
      aliasStr = b.alias or "";
    in
    "${keyStr}\t${b.desc}(${aliasStr})${modeStr}\t${tag} ${app} ${b.category}";

  tierOrder = [
    "managed"
    "documented"
  ];

  sortedEntries = lib.flatten (
    map (
      t:
      lib.mapAttrsToList (
        app: data: if data.tier == t then map (b: formatBinding app data.tier b) data.bindings else [ ]
      ) keybinds
    ) tierOrder
  );

  cheatsheetText = lib.concatStringsSep "\n" sortedEntries;

  # Cross-app conflict detection: kwm (global) vs documented (local)
  # kwm grabs keys at compositor level, so documented app bindings with same key+mods
  # will never reach the app when kwm is active — this is a real conflict
  kwmDefaultBindings = lib.filter (b: (b.mode or "default") == "default") keybinds.kwm.bindings;
  kwmIds = map (b: "${formatMods b.mods}+${b.key}") kwmDefaultBindings;

  documentedApps = lib.filterAttrs (_: data: data.tier == "documented") keybinds;

  crossConflicts = lib.flatten (
    lib.mapAttrsToList (
      app: data:
      lib.concatMap (
        b:
        let
          bid = "${formatMods b.mods}+${b.key}";
          matches = lib.filter (kid: kid == bid) kwmIds;
        in
        if matches != [ ] then [ "${app}: ${bid} → ${b.desc} conflicts with kwm global binding" ] else [ ]
      ) data.bindings
    ) documentedApps
  );

  # Warnings for cross-app conflicts (not errors — these are expected for Ctrl+key bindings
  # since kwm uses Super+key and apps use Ctrl+key, but Super+key conflicts are real)
  realConflicts = lib.filter (
    msg:
    # Only warn about Super+key conflicts (Ctrl+key in apps vs Super+key in kwm is fine)
    lib.hasInfix "Super+" msg
  ) crossConflicts;

in
lib.mkIf isDesktopEnabled {
  home.packages = [
    (pkgs.writeShellScriptBin "keybind-cheatsheet" ''
      ${pkgs.fuzzel}/bin/fuzzel --dmenu \
        --match-mode=fuzzy \
        --prompt="⌨ " \
        --width=80 \
        --lines=30 \
        --tab=4 <<'EOF'
      ${cheatsheetText}
      EOF
    '')
  ];

  # Emit warnings for cross-app conflicts at build time
  warnings = lib.optional (
    realConflicts != [ ]
  ) "keybind-registry: cross-app conflicts detected:\n${lib.concatStringsSep "\n" realConflicts}";
}
