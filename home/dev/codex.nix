# Codex CLI — OpenAI 的终端编码 agent
#
# 通过 LiteLLM 代理 (localhost:4000) 访问全部后端模型
# 免登录：自定义 provider requires_openai_auth=false
#
# 模型命名（对应 LiteLLM model_name）：
#   opencode-go/deepseek-v4-flash → Go 套餐（默认）
#   ollama/qwen3.6:27b-q4_K_M → 本地 Ollama（codex-oss 备用）
#
# 注意：Codex 0.130+ 强制 Responses API，
#       LiteLLM 自动桥接 Responses→Chat 以支持 Go 套餐等 Chat-only 后端。
#
# 架构：hm 模块的 settings 选项通过 home.file 创建符号链接到只读 Nix store，
#       Codex 需写入信任状态到 config.toml，故弃用 settings/enableMcpIntegration。
#       config.toml 通过 home.activation always-overwrite 种子化（rebuild 即恢复 SSOT）。
#       Codex 的 /model 改用 model_catalog_json 显示 LiteLLM 模型目录（替换 OpenAI 硬编码目录）。
#       model-catalog.json 从 api-providers.nix SSOT + 官方文档验证的上下文窗口生成。
#       MCP 合并手动复制模块逻辑；只有 context/skills/rules 走 hm 模块（只读，符号链接可接受）。
#       共享内容从 ../agents/shared.nix SSOT 消费
#
# hm 模块完整选项（2026-06-27 核实，home-manager 8d8a6cc）：
#   ✅ enable, package, enableMcpIntegration
#   ✅ settings            → ~/.codex/config.toml
#   ✅ profiles            → ~/.codex/<name>.config.toml
#   ✅ context             → ~/.codex/AGENTS.md
#   ✅ contextOverride     → ~/.codex/AGENTS.override.md
#   ✅ hooks               → ~/.codex/hooks.json
#   ✅ plugins, marketplaces
#   ✅ skills              → ~/.codex/skills/
#   ✅ rules               → ~/.codex/rules/<name>.rules
#   ❌ agents — hm 未暴露专用选项，语义与 OpenCode agents 不同（TOML 角色定义 vs markdown 指令），
#              直接通过 settings.agents 定义（格式：description + config_file + nickname_candidates）
{
  config,
  lib,
  pkgs,
  ...
}:
let
  shared = import ../agents/shared.nix { inherit lib; };
  catalog = import ../agents/codex-model-catalog.nix { inherit lib; };

  tomlFormat = pkgs.formats.toml { };

  # MCP server transform（映射 programs.mcp → Codex TOML）
  # programs.mcp 的 jsonFormat 对所有 server 填充全字段默认值（null/空），
  # Consumer 层按 transport 类型清理无效字段：
  #   url → streamable HTTP: 去除 command/args/env
  #   command → stdio: 去除 url
  #   同时过滤 null、空表、空数组。
  mcpEnabled = config.programs.mcp.enable or false;
  filterMcpServer =
    server:
    let
      # 1. 字段映射：disabled→enabled(反转), headers→http_headers（仅非空时）
      mapped =
        lib.removeAttrs server [
          "disabled"
          "headers"
        ]
        // (lib.optionalAttrs (server ? headers && server.headers != { } && !(server ? http_headers)) {
          http_headers = server.headers;
        })
        // {
          enabled = !(server.disabled or false);
        };
      # 2. 去 null（TOML 不支持）
      nonNull = lib.filterAttrs (_: v: v != null) mapped;
      # 3. 去 transport 不适用字段
      isUrl = (server.url or null) != null;
      transportClean =
        if isUrl then
          builtins.removeAttrs nonNull [
            "command"
            "args"
            "env"
          ]
        else
          builtins.removeAttrs nonNull [ "url" ];
      # 4. 去空容器（干净 TOML）
      clean = lib.filterAttrs (_: v: v != [ ] && v != { }) transportClean;
    in
    clean;
  transformedMcpServers = lib.optionalAttrs mcpEnabled (
    lib.mapAttrs (_name: filterMcpServer) (config.programs.mcp.servers or { })
  );

  codexSettings = {
    model = "opencode-go/deepseek-v4-flash";
    model_provider = "litellm";
    model_catalog_json = "${config.home.homeDirectory}/.codex/model-catalog.json";
    model_providers.litellm = {
      name = "LiteLLM Proxy";
      base_url = "http://localhost:4000/v1";
      wire_api = "responses";
      requires_openai_auth = false;
      env_key = "LITELLM_API_KEY";
    };
  }
  // lib.optionalAttrs (transformedMcpServers != { }) {
    mcp_servers = transformedMcpServers;
  };

  codexConfigSeed = tomlFormat.generate "codex-config" codexSettings;
in
{
  programs.codex = {
    enable = true;
    # settings / enableMcpIntegration 弃用：hm 模块通过 home.file
    # 创建符号链接到只读 Nix store，Codex 需写入信任状态到 config.toml 故不能使用。
    # MCP 合并手动处理（见上方），config.toml 通过 home.activation 种子化（见下方）。
    context = shared.combinedRules;
    skills = shared.skills;
    rules = shared.rules;
  };

  # always-overwrite: rebuild 始终恢复 Nix SSOT。
  # Codex 的 /model 会写入 config.toml 覆盖默认模型（并写入 OpenAI 模型名，LiteLLM 代理无此模型 → 损坏）。
  # 始终用种子覆盖保证 rebuild 后配置正确。信任状态在一次确认后恢复（sqlite 持久化）。
  home.activation.seedCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    CONFIG_FILE="$HOME/.codex/config.toml"

    # 清除旧 hm 模块残留的符号链接
    if [ -L "$CONFIG_FILE" ]; then
      rm -f "$CONFIG_FILE"
    fi

    mkdir -p "$(dirname "$CONFIG_FILE")"
    install -m644 ${codexConfigSeed} "$CONFIG_FILE"
  '';

  # Codex 模型目录 — 消除 metadata warning、启用并行工具调用和搜索
  home.file.".codex/model-catalog.json".text = builtins.toJSON catalog.catalog;

  home.sessionVariables = {
    LITELLM_API_KEY = "litellm-local";
  };

  # codex-oss: 备用路径直连本地 Ollama（代理不可用时）
  home.shellAliases = {
    codex-oss = "codex --oss -m qwen3.6:27b-q4_K_M";
  };
}
