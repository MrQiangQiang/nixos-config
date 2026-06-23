# Obsidian — markdown knowledge base browser (Karpathy LLM Wiki pattern)
#
# Architecture:
#   - Obsidian desktop app (pkgs.obsidian, unfree, v1.12.7)
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
{ pkgs, ... }:
{
  home.packages = [ pkgs.obsidian ];
}
