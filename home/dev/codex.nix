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
# 架构：settings.model_providers 写入 ~/.codex/config.toml（默认 provider）
#       profiles 预留备用（--profile <name> 覆盖 settings）
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
{ lib, ... }:
let
  shared = import ../agents/shared.nix { inherit lib; };
in
{
  programs.codex = {
    enable = true;
    enableMcpIntegration = true;

    settings = {
      model = "opencode-go/deepseek-v4-flash";
      model_provider = "litellm";
      model_providers = {
        litellm = {
          name = "LiteLLM Proxy";
          base_url = "http://localhost:4000/v1";
          wire_api = "responses";
          requires_openai_auth = false;
          env_key = "LITELLM_API_KEY";
        };
      };
    };

    context = shared.combinedRules;
    skills = shared.skills;
    rules = shared.rules;
  };

  # LiteLLM 本地代理密钥（仅 localhost 有效，安全设为环境变量）
  home.sessionVariables = {
    LITELLM_API_KEY = "litellm-local";
  };

  # codex-oss: 备用路径直连本地 Ollama（代理不可用时）
  home.shellAliases = {
    codex-oss = "codex --oss -m qwen3.6:27b-q4_K_M";
  };
}
