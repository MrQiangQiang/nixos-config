# Codex model catalog JSON generator
#
# SSOT: model names from api-providers.nix, context windows from official docs.
# Consumer: codex.nix 通过 home.file 部署 → ~/.codex/model-catalog.json
#
# 上下文窗口来源（2026-06-27 官方文档验证）：
#   deepseek-v4-*   https://api-docs.deepseek.com/quick_start/pricing        → 1,000,000
#   qwen3.7-*       https://www.alibabacloud.com/help/en/model-studio/       → 1,000,000
#   qwen3.6-plus    https://www.alibabacloud.com/help/en/model-studio/       → 1,000,000
#   glm-5.*         https://www.alibabacloud.com/help/en/model-studio/       →   198,000
#   kimi-k2.*       https://platform.moonshot.cn/docs/                       →   256,000
#   minimax-m3      https://platform.minimaxi.com/docs/                      → 1,000,000
#   minimax-m2.7    https://platform.minimaxi.com/docs/                      →   204,800
#   mimo-v2.5*      OpenRouter/HuggingFace card                              → 1,000,000
#   ollama-qwen3.6  ollama api/show                                        →   262,144
#
# 参数语义（Codex 源码验证）：
#   supports_parallel_tool_calls — 控制并行工具调用（API 请求参数），false=串行
#   supports_search_tool         — 控制搜索工具可用性 gates search_tool_enabled()
#   truncation_policy            — 工具输出截断阈值（compact/session/user_shell）
#   context_window               — 上下文窗口上限（含 effective_context_window_percent 95%）

{
  lib,
  ...
}:
let
  api = import ./api-providers.nix { inherit lib; };

  # Per-model context windows (verified 2026-06-27)
  contextWindows = {
    "deepseek-v4-flash" = 1000000;
    "deepseek-v4-pro" = 1000000;
    "qwen3.7-max" = 1000000;
    "qwen3.7-plus" = 1000000;
    "qwen3.6-plus" = 1000000;
    "glm-5.2" = 198000;
    "glm-5.1" = 198000;
    "kimi-k2.7-code" = 256000;
    "kimi-k2.6" = 256000;
    "minimax-m3" = 1000000;
    "minimax-m2.7" = 204800;
    "mimo-v2.5" = 1000000;
    "mimo-v2.5-pro" = 1000000;
  };

  defaultContextWindow = 131072; # fallback: 128k (should never be used)

  common = contextWindow: {
    context_window = contextWindow;
    max_context_window = contextWindow;
    base_instructions = "You are Codex, a coding agent. You and the user share the same workspace and collaborate to achieve the user's goals. You have access to tools for reading, writing, editing, searching, and running commands.";
    shell_type = "default";
    visibility = "list";
    supported_in_api = true;
    priority = 50;
    supports_parallel_tool_calls = true;
    supports_reasoning_summaries = true;
    default_reasoning_summary = "none";
    support_verbosity = false;
    supports_image_detail_original = false;
    supports_search_tool = true;
    web_search_tool_type = "text";
    truncation_policy = {
      mode = "tokens";
      limit = 10000;
    };
    supported_reasoning_levels = [ ];
  };

  # Generate model entry: <provider>/<model> → ModelInfo
  mkEntry =
    provider: modelName:
    let
      displayName = "${provider}/${modelName}";
      ctxWin = contextWindows.${modelName} or defaultContextWindow;
    in
    (common ctxWin)
    // {
      slug = "${provider}/${modelName}";
      display_name = displayName;
    };

  # Collect all models from api-providers.nix
  providerModels = lib.concatLists (
    lib.mapAttrsToList (
      providerName: provider:
      lib.mapAttrsToList (modelName: _meta: mkEntry providerName modelName) provider.models
    ) api.providers
  );

  # Ollama local models (manual — local models are dynamic)
  ollamaEntries = [
    (
      (common 262144)
      // {
        slug = "ollama/qwen3.6:27b-q4_K_M";
        display_name = "Qwen 3.6 27B (Ollama local)";
      }
    )
  ];
in
{
  # Full model catalog as Nix attrset — consumer serializes to JSON
  catalog = {
    models = providerModels ++ ollamaEntries;
  };
}
