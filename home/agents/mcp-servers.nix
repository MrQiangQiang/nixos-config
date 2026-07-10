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
#   parallel-search — 全网搜索 (LLM-optimized web search MCP)
#         web_search 一次调用返回 URL + 引文摘录（search+fetch 合一），另有 web_fetch 获取全文。
#         免费匿名使用，无需 API key。ECC v2.0.0 (github.com/affaan-m/ECC) 背书为 opt-in MCP。
#
#   context7 — 文档搜索引擎 (library/framework 官方文档)
#         远程 MCP: https://mcp.context7.com/mcp
#         免费匿名 tier（IP 速率限制），API key 仅用于提升速率上限
#
# AGENTS.md: git-cloned with ~/knowledge/ repo (Karpathy pattern)
{ config, ... }:
let
  qmdPort = config.custom.qmd.port;
in
{
  programs.mcp = {
    enable = true;
    servers.qmd = {
      url =
        if config.custom.qmd.enable then
          "http://localhost:${toString qmdPort}/mcp"
        else
          # tailnet 域名硬编码：tail0f7af0.ts.net 由 Tailscale 控制台分配，不可 nixify。
          # desktop-1 是唯一 qmd 索引节点，tailscale-serve.nix 暴露端口到 tailnet。
          "https://desktop-1.tail0f7af0.ts.net/mcp";
    };
    servers.context7 = {
      url = "https://mcp.context7.com/mcp";
    };
    servers.parallel-search = {
      url = "https://search.parallel.ai/mcp";
    };
  };
}
