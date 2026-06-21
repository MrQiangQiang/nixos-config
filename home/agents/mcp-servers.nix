# MCP server configuration SSOT (Single Source of Truth)
#
# Uses home-manager's built-in programs.mcp module.
# All MCP-capable AI agents (opencode, trae-cn, etc.) read from this config.
#
# Servers:
#   qmd — Knowledge base search (BM25 + vector + rerank)
#         desktop-1: localhost:8181 (qmd-mcp service)
#         laptop-1:  localhost:8181 (SSH tunnel to desktop-1)
#
# AGENTS.md: Deployed separately to ~/knowledge/AGENTS.md (Karpathy pattern)
{ config, ... }:
{
  programs.mcp = {
    enable = true;
    servers.qmd = {
      url = "http://localhost:8181/mcp";
    };
  };
}
