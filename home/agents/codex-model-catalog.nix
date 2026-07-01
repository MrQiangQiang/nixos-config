# Codex model catalog JSON generator
#
# SSOT: model definitions (name + context_window + reasoningEfforts) from api-providers.nix.
# Consumer: codex.nix 通过 home.file 部署 → ~/.codex/model-catalog.json
#
# 参数语义（Codex 源码验证）：
#   supports_parallel_tool_calls — 控制并行工具调用（API 请求参数），false=串行
#   supports_search_tool         — 控制搜索工具可用性 gates search_tool_enabled()
#   truncation_policy            — 工具输出截断阈值（compact/session/user_shell）
#   context_window               — 上下文窗口上限（含 effective_context_window_percent 95%）
#   default_reasoning_level      — 默认 reasoning effort（Codex UI 选中模型后默认应用）
#   supported_reasoning_levels   — 可选 effort 列表（UI 弹窗显示）
#
# supported_reasoning_levels 不能为空数组：
#   open_all_models_popup (model_popups.rs:184) 计算 single_supported_effort = len==1，
#   空数组时 single_supported_effort=false → 设置 dismiss_parent_on_child_accept=true
#   期望子视图接受时关闭父视图。但 open_reasoning_popup (model_popups.rs:382-401)
#   在 choices.len()<=1 时（空数组 fallback push 默认 effort）直接 apply_model_and_effort
#   不推入子视图，dismiss_after_child_accept 永远不被消费 → 父视图卡住，UI 死锁。
#   官方测试代码统一用单元素 [medium]（tests/helpers.rs:267, tests/model_switching.rs:106）。
#
# Variant 来源（2026-06-29 官方文档 + opencode transform.ts 源码验证）：
#   deepseek-v4-*: reasoning_effort high/max（DS 文档：低档静默映射→high, xhigh→max）
#   glm-5.2:       reasoning_effort high/max（opencode transform.ts:690-694 显式处理）
#   minimax-m3:    thinking toggle none/medium（opencode transform.ts:672-679）
#   mimo-v2.5*:    reasoning_effort low/medium/high（opencode 内置 catalog）
#   kimi*:         始终思考 / 仅 toggle，无 effort API（opencode transform.ts:709 排除）
#   qwen*:         无 reasoning_effort API（opencode transform.ts:711 排除）
#   其他:           单元素 [medium] — 无 effort 控制，UI 不弹窗但避免空数组死锁

{
  lib,
  ollamaContextLength,
  ollamaModel,
  ...
}:
let
  api = import ./api-providers.nix { inherit lib; };

  defaultContextWindow = 131072; # fallback: 128k

  # Effort 描述（Codex UI 显示）
  effortDesc = {
    none = "No reasoning";
    low = "Fast responses with lighter reasoning";
    medium = "Balances speed and reasoning depth for everyday tasks";
    high = "Greater reasoning depth for complex problems";
    max = "Maximum reasoning depth for the most complex problems";
    xhigh = "Maximum reasoning depth for the most complex problems";
  };

  # SSOT effort 名 → Codex ReasoningEffort 枚举名
  # Codex 无 "max" 枚举值，映射到 "xhigh"（DeepSeek API 内部将 xhigh 映射回 max）
  mapEffort = e: if e == "max" then "xhigh" else e;

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
    experimental_supported_tools = [ ];
  };

  # 从 SSOT reasoningEfforts 生成 Codex supported_reasoning_levels
  mkReasoningLevels =
    efforts:
    let
      levels = map (e: {
        effort = mapEffort e;
        description = effortDesc.${e} or "Custom reasoning effort";
      }) efforts;
      defaultEffort = mapEffort (builtins.head efforts);
    in
    {
      supported_reasoning_levels = levels;
      default_reasoning_level = defaultEffort;
    };

  # 无 effort 控制能力的模型：单元素 [medium]（避免空数组死锁，UI 不弹窗直接应用）
  defaultReasoningLevels = {
    supported_reasoning_levels = [
      {
        effort = "medium";
        description = effortDesc.medium;
      }
    ];
    default_reasoning_level = "medium";
  };

  # Generate model entry: <provider>/<model> → ModelInfo
  mkEntry =
    provider: modelName: modelMeta:
    let
      ctxWin = modelMeta.contextWindow or defaultContextWindow;
      efforts = modelMeta.reasoningEfforts or null;
      reasoningLevels = if efforts != null then mkReasoningLevels efforts else defaultReasoningLevels;
    in
    (common ctxWin)
    // {
      slug = "${provider}/${modelName}";
      display_name = "${provider}/${modelName}";
    }
    // reasoningLevels;

  # Collect all models from api-providers.nix
  providerModels = lib.concatLists (
    lib.mapAttrsToList (
      providerName: provider: lib.mapAttrsToList (mkEntry providerName) provider.models
    ) api.providers
  );

  # Ollama local models (SSOT: modules/ollama.nix → osConfig.custom.ollama.* → 必填参数)
  ollamaEntries = [
    (
      (common ollamaContextLength)
      // {
        slug = "ollama/${ollamaModel}";
        display_name = "Qwen 3.6 27B (Ollama local)";
      }
      // defaultReasoningLevels
    )
  ];
in
{
  # Full model catalog as Nix attrset — consumer serializes to JSON
  catalog = {
    models = providerModels ++ ollamaEntries;
  };
}
