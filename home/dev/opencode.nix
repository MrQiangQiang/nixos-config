# OpenCode — SST/Anomaly 的终端 AI 编码 agent
#
# Provider 架构：分治原则（2026-06-29 models.dev 数据验证）
#
#   LiteLLM Proxy — 多工具共享模型（SSOT: api-providers.nix）
#     所有需要 API key 的付费模型经 LiteLLM 统一路由
#     成本追踪、密钥管理、多工具（OpenCode/Codex/Claude/Trae）复用
#     含 Ollama 本地模型（多工具通过 LiteLLM 共享访问）
#
#   OpenCode Zen  — 工具专属免费模型（SSOT: opencode 内置 OpencodePlugin）
#     models.dev 注入 71 个模型 → OpencodePlugin 检测无 API key →
#     自动禁用 50 个付费模型（cost.input > 0）→ 仅展示 21 个免费模型
#     与 LiteLLM 零重叠（Zen free ∩ api-providers.nix = ∅）
#
#   opencode-go   — models.dev 附带注入，14/14 模型与 LiteLLM 100% 重叠
#     无 API key 不可用，为无副作用展示（不删除不配置）
#
# 运行时切换模型：在 OpenCode 中 /model 即可选择
{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  shared = import ../agents/shared.nix { inherit lib pkgs; };
  apiProviders = (import ../agents/api-providers.nix).providers;

  # Ollama 本地模型（SSOT: modules/ollama.nix → osConfig.custom.ollama.model）
  ollamaModel = osConfig.custom.ollama.model;

  # 模型选择 UI 显示前缀
  providerLabel = {
    opencode-go = "Go";
    deepseek = "DS API";
    glm-coding-plan = "GLM Plan";
  };

  # 从 api-providers.nix SSOT 自动生成 litellm 模型列表
  # modelMeta 包含 { cost, reasoning, reasoningEfforts, ... } 等元数据，逐字段传递给 OpenCode
  # reasoning — OpenCode variant 选择器的门控（transform.ts:666），来自 SSOT reasoning 字段
  #   设为 true 的模型：deepseek-v4-*, glm-5.2, minimax-m3, mimo-v2.5*
  #   设为 false 的模型：qwen*（无 reasoning_effort API）、kimi*（始终/仅 toggle）、glm-5.1、minimax-m2.7
  litellmCloudModels = builtins.foldl' (
    acc: providerName:
    let
      provider = apiProviders.${providerName};
    in
    acc
    // lib.mapAttrs' (
      modelName: modelMeta:
      lib.nameValuePair "${providerName}/${modelName}" {
        name = "${providerLabel.${providerName} or providerName}: ${modelName}";
        cost = modelMeta.cost;
        reasoning = modelMeta.reasoning; # SSOT: 控制 variant 选择器显隐
      }
    ) provider.models
  ) { } (builtins.attrNames apiProviders);
in
{
  # ── Provider 分治架构 ────────────────────────────────────────
  # 详见文件头注释。LiteLLM = 多工具共享付费模型，Zen = opencode 专属免费模型。
  # OpenCode 不对 @ai-sdk/openai-compatible 做 /v1/models auto-discovery
  # （provider.ts:1403: models 无显式条目 → 模型数=0 → provider 被删除），
  # 因此必须在此显式列出 LiteLLM 模型。

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      model = "opencode-go/deepseek-v4-flash";

      provider = {
        # LiteLLM Proxy — 多工具共享付费模型（SSOT: api-providers.nix → 自动生成模型列表）
        "litellm" = {
          npm = "@ai-sdk/openai-compatible";
          name = "LiteLLM Proxy";
          options = {
            baseURL = "http://localhost:${toString config.custom.litellm.port}/v1";
            apiKey = "litellm-local";
          };
          models = litellmCloudModels // {
            # Ollama 本地模型（SSOT: osConfig.custom.ollama，通过 LiteLLM 多工具共享）
            "ollama/${ollamaModel}".name = "Ollama: Qwen3.6 27B (Q4_K_M)";
          };
        };
      };
    };
    tui.theme = "system";

    context = shared.combinedContext;
    commands = shared.commands;
    skills = shared.skills;
    agents = shared.agents;
  };
}
