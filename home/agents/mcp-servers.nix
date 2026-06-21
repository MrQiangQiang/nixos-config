# MCP server configuration SSOT (Single Source of Truth)
#
# Uses home-manager's built-in programs.mcp module.
# All MCP-capable AI agents (opencode, trae-cn, etc.) read from this config.
#
# Servers:
#   qmd — Knowledge base search (BM25 + vector + rerank)
#         runs only on desktop-1 (Qwen3-Embedding + Reranker + query-expansion models).
#         desktop-1: localhost:8181 (qmd-mcp systemd service)
#         laptop-1:  https://desktop-1.tail0f7af0.ts.net/mcp (Tailscale Serve)
#                    requires `tailscale serve --bg 8181` on desktop-1.
#         Non-desktop-1 machines connect via Tailscale mesh; no SSH tunnel needed.
#
# AGENTS.md: git-cloned with ~/knowledge/ repo (Karpathy pattern)
{ config, lib, ... }:
let
  hasQmd = config.custom.qmd.enable or false;
in {
  programs.mcp = {
    enable = true;
    servers.qmd = {
      url = if hasQmd
        then "http://localhost:8181/mcp"
        else "https://desktop-1.tail0f7af0.ts.net/mcp";
    };
  };
}
