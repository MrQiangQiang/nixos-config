# Codex CLI — OpenAI 的终端编码 agent
#
# 通过 LiteLLM 代理 (localhost:4000) 访问全部后端模型
# 免登录：自定义 provider requires_openai_auth=false
#
# 模型命名（对应 LiteLLM model_name）：
#   opencode-go/deepseek-v4-flash → Go 套餐
#   ollama/qwen3.6:27b-q4_K_M → 本地 Ollama
#
# 注意：Codex 0.130+ 强制 Responses API，
#       LiteLLM 自动桥接 Responses→Chat 以支持 Go 套餐等 Chat-only 后端。
#
# 备用路径：codex-oss 别名仍可用（直接连本地 Ollama，绕过代理）
#
# hm 模块选项（2026-06-27 核实）：
#   ✅ enable, enableMcpIntegration, settings, context, skills, rules
#   ❌ commands — Codex 仅内置 50+/ 命令，不支持自定义
#   ❌ agents   — CLI 支持 ~/.codex/agents/*.toml，hm 模块未暴露选项
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
    };

    # Codex profile 通过 LiteLLM 代理访问所有后端
    profiles.litellm = {
      model = "opencode-go/deepseek-v4-flash";
    };

    context = shared.combinedRules;
    skills = shared.skills;
    rules = shared.rules;
  };

  # LiteLLM 代理 model_provider（写入 CODEX_HOME/config.toml）
  # Codex 模块的 settings 生成 TOML，profiles 生成独立 .toml 文件
  # model_providers 嵌套表需要通过 home.file 单独写入
  home.file.".codex/litellm-provider.toml".text = ''
    [model_providers.litellm]
    name = "LiteLLM Proxy"
    base_url = "http://localhost:4000/v1"
    wire_api = "responses"
    requires_openai_auth = false
    env_key = "LITELLM_API_KEY"
  '';

  # LiteLLM 的 Responses API 路由需要 model_provider 引用
  # 通过 home.file 单独写入，与 profiles.litellm 配合使用
  home.file.".codex/litellm.config.toml".text = ''
    model = "opencode-go/deepseek-v4-flash"
    model_provider = "litellm"
  '';

  # --oss 备用路径：直连本地 Ollama（代理不可用时）
  home.shellAliases = {
    codex-oss = "codex --oss -m qwen3.6:27b-q4_K_M";
    codex-proxy = "LITELLM_API_KEY=litellm-local codex --profile litellm";
  };
}
