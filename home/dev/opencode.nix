# OpenCode — SST/Anomaly 的终端 AI 编码 agent
#
# 主路径：通过 LiteLLM 代理 (localhost:4000) 访问所有后端模型
# 后备路径：Ollama 直连（代理不可用时仍可用）
#
# 模型列表从 api-providers.nix (SSOT) 自动派生，无需手动同步。
# OpenCode 不对 @ai-sdk/openai-compatible 做 /v1/models auto-discovery
# （provider.ts:1403: models 无显式条目 → 模型数=0 → provider 被删除），
# 因此必须在此显式列出所有模型。
#
# 运行时切换模型：在 OpenCode 中 /model 即可选择
{ lib, ... }:
let
  shared = import ../agents/shared.nix { inherit lib; };
  apiProviders = (import ../agents/api-providers.nix { inherit lib; }).providers;

  # 模型选择 UI 显示前缀
  providerLabel = {
    opencode-go = "Go";
    deepseek = "DS API";
    glm-coding-plan = "GLM Plan";
  };

  # 从 api-providers.nix SSOT 自动生成 litellm 模型列表
  # modelMeta 包含 { cost, limit } 等元数据，逐字段传递给 OpenCode
  litellmCloudModels = builtins.foldl' (acc: providerName:
    let provider = apiProviders.${providerName};
    in
    acc // lib.mapAttrs' (modelName: modelMeta:
      lib.nameValuePair "${providerName}/${modelName}" {
        name = "${providerLabel.${providerName} or providerName}: ${modelName}";
        cost = modelMeta.cost or {};  # mkModel 保证必有一致，or {} 仅防意外
      }
    ) provider.models
  ) {} (builtins.attrNames apiProviders);
in
{
  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      model = "opencode-go/deepseek-v4-flash";

      provider = {
        # LiteLLM 代理 — 统一入口（模型列表从 api-providers.nix SSOT 自动派生）
        # 显式列出全部模型（OpenCode 不做 auto-discovery，见 provider.ts:1403）
        "litellm" = {
          npm = "@ai-sdk/openai-compatible";
          name = "LiteLLM Proxy (all backends)";
          options = {
            baseURL = "http://localhost:4000/v1";
            apiKey = "litellm-local";
          };
          models = litellmCloudModels // {
            # Ollama 本地模型（非 API provider，手动指定）
            "ollama/qwen3.6:27b-q4_K_M".name = "Ollama: Qwen3.6 27B (Q4_K_M)";
          };
        };

        # Ollama 直连 — 代理不可用时的后备
        "ollama" = {
          npm = "@ai-sdk/openai-compatible";
          name = "Ollama (local, direct)";
          options.baseURL = "http://localhost:11434/v1";
          models."qwen3.6:27b-q4_K_M" = {
            name = "Qwen3.6 27B (Q4_K_M)";
            limit = {
              context = 262144;
              output = 8192;
            };
          };
        };
      };
    };
    tui.theme = "system";

    context = shared.combinedRules;
    commands = shared.commands;
    skills = shared.skills;
    agents = shared.agents;
  };
}