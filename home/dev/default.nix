{ config, lib, pkgs, osConfig, palette, ... }:

let
  traePkg = pkgs.trae-cn.override {
    vscodeDarkTheme = palette.vscode.dark_name;
    vscodeLightTheme = palette.vscode.light_name;
  };

  traeSettings = {
    "AI.toolcall.v2.ide.command.mode" = "whitelist";
    "AI.toolcall.v2.solo.command.mode" = "whitelist";
    "http.proxyStrictSSL" = false;
    "extensions.autoUpdate" = false;
    "extensions.autoCheckUpdates" = false;
    "terminal.integrated.fontFamily" = builtins.head osConfig.fonts.fontconfig.defaultFonts.monospace;
    "editor.fontFamily" = "'${builtins.head osConfig.fonts.fontconfig.defaultFonts.monospace}', monospace";
  };

  traeSettingsRemove = [
    "window.autoDetectColorScheme"
    "workbench.preferredDarkColorTheme"
    "workbench.preferredLightColorTheme"
    "chat.fontFamily"
    "chat.codeBlock.fontFamily"
    "chat.input.fontFamily"
  ];

  traeSettingsJson = (pkgs.formats.json { }).generate "trae-settings" traeSettings;
  traeSettingsPath = "${config.home.homeDirectory}/.config/Trae CN/User/settings.json";

  rosePineExt = pkgs.open-vsx-release.mvllow.rose-pine;
  rosePineExtDir = "${rosePineExt}/share/vscode/extensions/mvllow.rose-pine";

  extDir = "${config.home.homeDirectory}/.trae-cn/extensions";

  nixExtIds = [ "mvllow.rose-pine" ];

  mkExtEntry = { id, dir, publisher, version ? "1.0.0" }: {
    identifier = { id = id; uuid = ""; };
    version = version;
    relativeLocation = id;
    location = {
      "$mid" = 1;
      fsPath = "${extDir}/${id}";
      path = "${extDir}/${id}";
      scheme = "file";
    };
    metadata = {
      id = "";
      publisherId = "";
      publisherDisplayName = publisher;
      targetPlatform = "undefined";
      isApplicationScoped = false;
      updated = false;
      isPreReleaseVersion = false;
      installedTimestamp = 0;
      preRelease = false;
    };
  };

  nixExts = [
    (mkExtEntry {
      id = "mvllow.rose-pine";
      dir = rosePineExtDir;
      publisher = "mvllow";
      version = rosePineExt.version;
    })
  ];

  nixExtJson = (pkgs.formats.json { }).generate "nix-extensions" nixExts;
  nixIdsJson = (pkgs.formats.json { }).generate "nix-ext-ids" nixExtIds;
in
{
  imports = [ ./toolchain.nix ./opencode.nix ];

  home.packages = [ traePkg ];

  home.activation.traeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$(dirname ${lib.escapeShellArg traeSettingsPath})"
    if [ -f ${lib.escapeShellArg traeSettingsPath} ]; then
        merged=$(${lib.getExe pkgs.jq} -s '.[0] * .[1] | del(${lib.concatStringsSep ", " (map (k: ''."${k}"'') traeSettingsRemove)})' ${lib.escapeShellArg traeSettingsPath} ${traeSettingsJson})
        printf '%s\n' "$merged" > ${lib.escapeShellArg traeSettingsPath}
      else
        $DRY_RUN_CMD cp ${traeSettingsJson} ${lib.escapeShellArg traeSettingsPath}
        $DRY_RUN_CMD chmod u+w ${lib.escapeShellArg traeSettingsPath}
      fi
  '';

  home.activation.traeExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p ${extDir}

    if [ -d "${rosePineExtDir}" ]; then
      $DRY_RUN_CMD ln -snf ${rosePineExtDir} ${extDir}/mvllow.rose-pine
    fi

    if [ -f ${extDir}/extensions.json ]; then
      merged=$(${lib.getExe pkgs.jq} --argjson nix_ids "$(cat ${nixIdsJson})" --argjson nix_exts "$(cat ${nixExtJson})" '
        (. // []) as $existing |
        ($existing | map(select(.identifier.id as $id | $nix_ids | index($id) | not))) as $user |
        $user + $nix_exts
      ' ${extDir}/extensions.json)
      printf '%s\n' "$merged" > ${extDir}/extensions.json
    else
      $DRY_RUN_CMD cp ${nixExtJson} ${extDir}/extensions.json
      $DRY_RUN_CMD chmod u+w ${extDir}/extensions.json
    fi

    if [ -f ${extDir}/.obsolete ]; then
      cleaned=$(${lib.getExe pkgs.jq} --argjson nix_ids "$(cat ${nixIdsJson})" '
        with_entries(select(.key as $k | $nix_ids | map(. + "-" as $prefix | $k | startswith($prefix)) | any | not))
      ' ${extDir}/.obsolete)
      printf '%s\n' "$cleaned" > ${extDir}/.obsolete
    fi
  '';
}
