{ config, lib, pkgs, osConfig, keybinds, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;

  formatMods = mods: lib.concatStringsSep "+" mods;

  tierTag = tier:
    if tier == "universal" then "🌍"
    else if tier == "managed" then "⚙"
    else "📖";

  formatBinding = app: tier: b:
    let
      tag = tierTag tier;
      modStr = formatMods b.mods;
      keyStr = if modStr == "" then b.key else "${modStr}+${b.key}";
      modeStr = lib.optionalString (b.mode or null != null) " [${b.mode}]";
    in "${tag} [${app}] ${b.desc}${modeStr}  │  ${keyStr}";

  tierOrder = [ "universal" "managed" "documented" ];

  sortedEntries = lib.flatten (map (t:
    lib.mapAttrsToList (app: data:
      if data.tier == t then
        map (b: formatBinding app data.tier b) data.bindings
      else []
    ) keybinds
  ) tierOrder);

  cheatsheetText = lib.concatStringsSep "\n" sortedEntries;
in
lib.mkIf isDesktopEnabled {
  home.packages = [
    (pkgs.writeShellScriptBin "keybind-cheatsheet" ''
      ${pkgs.fuzzel}/bin/fuzzel --dmenu \
        --prompt="⌨ 快捷键 > " \
        --width=70 \
        --lines=25 <<EOF
      ${cheatsheetText}
      EOF
    '')
  ];
}
