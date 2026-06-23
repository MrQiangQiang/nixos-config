# Dev toolchain: mise (version switching + env injection + task runner)
#
# Architecture: Nix declares mise config -> mise manages all toolchain versions
#
# Declarative guarantee:
#   - programs.mise.globalConfig -> global tool versions + settings declared in
#     .nix (read-only symlink at ~/.config/mise/config.toml)
#   - `mise use --global` unavailable (config.toml is read-only) -> force
#     changes through .nix
#
# Tool discoverability:
#   - Interactive shell (fish): mise activate fish (PATH mode, full features)
#   - Non-interactive (Trae CN, systemd, GUI): mise shims (home.sessionPath)
#   - Shim limitation: does NOT load [env] vars or run hooks
#
# Version resolution:
#   - Project mise.toml > global config.toml
#   - python3.13 exact match, python takes first version in list
#   - Virtual envs: python.uv_venv_auto = "source" auto-activates .venv
#
# No isDesktopEnabled guard: dev tools needed without desktop too.
{ pkgs, lib, ... }:

{
  programs.mise = {
    enable = true;

    # Bash is a login shell springboard (exec fish), no mise activate needed
    enableBashIntegration = false;

    # Fish is the interactive shell, needs mise activate (added to
    # interactiveShellInit by the home-manager module)
    enableFishIntegration = true;

    # Global config (declarative, generates read-only ~/.config/mise/config.toml)
    # Add/modify/remove tools: edit this file -> nixos-rebuild switch (auto
    # triggers mise install via home.activation below)
    # Quick one-off experiments: mise use (project) / mise exec (one-shot)
    globalConfig = {
      tools = {
        node = {
          version = "24";
          corepack = true;
        };
        python = [
          "3.11"
          "3.12"
          "3.13"
          "3.14"
        ];
        go = "1.24";
        zig = "0.14";
        rust = "stable";
        uv = "latest";
        "pipx:ruff" = "latest";
      };

      # Security policy + compile settings + Python venv auto-activation
      settings = {
        node.compile = false; # Use prebuilt binaries (source build needs python/cc)
        python.compile = false; # Use prebuilt binaries (source build needs cc)
        lockfile = true;
        minimum_release_age = "5d";
        python.uv_venv_auto = "source";
      };
    };
  };

  # Shim dir on desktop session PATH so non-interactive contexts (Trae CN,
  # systemd, GUI apps) can find mise-managed tools via shims.
  # mise install/use auto-calls reshim, shims stay in sync.
  # Note: shims do NOT load [env] vars or run hooks (mise known limitation)
  home.sessionPath = [
    "$HOME/.local/share/mise/shims"
  ];

  # Auto-sync tool installations on nixos-rebuild switch.
  # The `run` function is provided by home-manager activation scripts — it
  # executes the command on live runs and just echoes it on dry runs.
  # mise install checks each tool version before installing — already-installed
  # tools are skipped, so this is fast on incremental changes.
  # Network failures are non-fatal: the || fallback ensures switch succeeds
  # even if a download fails (e.g. offline); run 'mise install' manually then.
  # PATH: rustup-init needs curl/wget, other tools may need git
  home.activation.miseInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${lib.makeBinPath [ pkgs.curl pkgs.wget pkgs.git ]}:$PATH"
    run ${lib.getExe pkgs.mise} install --yes 2>&1 || echo "mise: some tools failed to install, run 'mise install' manually"
  '';
}
