# MCP server configuration SSOT (Single Source of Truth)
#
# Uses home-manager's built-in programs.mcp module.
# All MCP-capable AI agents (opencode, trae-cn, etc.) read from this config.
#
# Servers:
#   qmd — Knowledge base search (BM25 + vector + rerank)
#         runs only on desktop-1 (Qwen3-Embedding + Reranker + query-expansion models).
#         desktop-1: localhost:8181 (qmd-mcp systemd service)
#         laptop-1:  https://desktop-1.<tailnet-domain>/mcp (Tailscale Serve)
#                    requires `tailscale serve --bg 8181` on desktop-1.
#         Non-desktop-1 machines connect via Tailscale mesh; no SSH tunnel needed.
#
# AGENTS.md: git-cloned with ~/knowledge/ repo (Karpathy pattern)
{
  config,
  osConfig,
  ...
}:
{
  programs.mcp = {
    enable = true;
    servers.qmd = {
      url =
        if config.custom.qmd.enable then
          "http://localhost:${toString config.custom.qmd.port}/mcp"
        else
          # tailnet 域名 SSOT: osConfig.custom.tailnet.domain (modules/tailscale.nix)
          # desktop-1 是唯一 qmd 索引节点，tailscale-serve.nix 暴露端口到 tailnet。
          "https://desktop-1.${osConfig.custom.tailnet.domain}/mcp";
    };
  };
}
