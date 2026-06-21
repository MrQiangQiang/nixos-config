{ config, lib, pkgs, osConfig, palette, ... }:
let
  cfg = config.custom.trae-cn;

  traePkg = pkgs.trae-cn.override {
    vscodeDarkTheme = palette.vscode.dark_name;
    vscodeLightTheme = palette.vscode.light_name;
  };

  # ── settings ──

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

  # ── extensions ──

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

  # ── MCP (from SSOT) ──
  # Transform programs.mcp.servers to Trae CN mcp.json format.
  # Trae CN reads from ~/.trae-cn/mcp.json
  # Format: {"mcpServers": {name: {url|command, args?, env?, headers?}}}
  # Note: env {file=...;} submodules are opencode-specific, not supported by Trae CN.
  traeMcpServers = lib.mapAttrs (_: server:
    lib.filterAttrs (k: v:
      k != "enabled" && v != null && v != [ ] && v != { }
    ) server
  ) config.programs.mcp.servers;

  traeMcpJson = (pkgs.formats.json { }).generate "trae-mcp" {
    mcpServers = traeMcpServers;
  };
in
{
  options.custom.trae-cn = {
    enable = lib.mkEnableOption "Trae CN IDE";
    sandbox = {
      extraReadWrite = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        description = "Additional read-write paths for sandbox";
      };
      extraReadOnly = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        description = "Additional read-only paths for sandbox";
      };
    };
    network = {
      defaultPolicy = lib.mkOption {
        type = lib.types.enum [ "allow" "deny" ];
        default = "allow";
        description = "Default network policy";
      };
      extraAllow = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        description = "Additional network allow entries";
      };
      extraDeny = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        description = "Additional network deny entries";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ traePkg ];

    # sandbox — read-only security policy (home.file: Nix store symlink)
    home.file.".trae-cn/sandbox.json".text = builtins.toJSON {
      filesystem = {
        readWrite = cfg.sandbox.extraReadWrite;
        readOnly = cfg.sandbox.extraReadOnly;
      };
      network = {
        default = cfg.network.defaultPolicy;
        allow = cfg.network.extraAllow;
        deny = cfg.network.extraDeny;
      };
    };

    # MCP servers — read-only symlink (Nix store)
    # Source: programs.mcp.servers (SSOT in home/agents/mcp-servers.nix)
    # To add/modify MCP servers, edit home/agents/mcp-servers.nix (not this file)
    home.file.".trae-cn/mcp.json".source = traeMcpJson;

    # settings — writable merge (home.activation: preserves IDE runtime writes)
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

    # extensions — writable merge (home.activation: preserves user-installed extensions)
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
  };
}
