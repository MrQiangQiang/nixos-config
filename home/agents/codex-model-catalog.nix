# Codex model catalog JSON generator
#
# SSOT: model definitions (name + context_window) from api-providers.nix.
# Consumer: codex.nix 通过 home.file 部署 → ~/.codex/model-catalog.json
#
# 参数语义（Codex 源码验证）：
#   supports_parallel_tool_calls — 控制并行工具调用（API 请求参数），false=串行
#   supports_search_tool         — 控制搜索工具可用性 gates search_tool_enabled()
#   truncation_policy            — 工具输出截断阈值（compact/session/user_shell）
#   context_window               — 上下文窗口上限（含 effective_context_window_percent 95%）

{
  lib,
  ollamaContextLength ? 262144,
  ollamaModel ? "qwen3.6:27b-q4_K_M",
  ...
}:
let
  api = import ./api-providers.nix { inherit lib; };

  defaultContextWindow = 131072; # fallback: 128k

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
    provider: modelName: modelMeta:
    let
      ctxWin = modelMeta.contextWindow or defaultContextWindow;
    in
    (common ctxWin)
    // {
      slug = "${provider}/${modelName}";
      display_name = "${provider}/${modelName}";
    };

  # Collect all models from api-providers.nix
  providerModels = lib.concatLists (
    lib.mapAttrsToList (
      providerName: provider: lib.mapAttrsToList (mkEntry providerName) provider.models
    ) api.providers
  );

  # Ollama local models (SSOT: modules/ollama.nix → passed as ollamaModel param)
  ollamaEntries = [
    (
      (common ollamaContextLength)
      // {
        slug = "ollama/${ollamaModel}";
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
