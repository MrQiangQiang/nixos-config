{ ... }:
{
  imports = [
    ./litellm.nix
    ./toolchain.nix
    ./opencode.nix
    ./trae-cn.nix
    ./codex.nix
    ./claude-code.nix
    ./qmd.nix
    ./obsidian.nix
    ./obsidian-plugins.nix
  ];
}
