# API Provider SSOT — 所有 AI 工具的模型后端唯一来源
#
# LiteLLM 代理从此文件读取 provider 配置，自动生成 model_list 和路由规则。
# 修改 provider 定义（url/key_ref/models）→ LiteLLM 配置自动更新 → 所有工具立即可用。
#
# 新增 provider → 在 providers attrset 加一项 + modules/opencode.nix 声明 agenix 密钥。
# 新增模型 → mkModel { input = X; output = Y; }（必填，漏写构建失败）
# 切换工具后端 → 运行时选择模型即可（所有模型对所有工具可见）。
#
# 价格来源（SSOT）：
#   opencode-go:  https://opencode.ai/docs/zh-cn/go（官方 Go 套餐定价表）
#                同步命令：curl -s https://opencode.ai/docs/zh-cn/go | grep -oP '每 1M tokens 的价格.*$'
#   deepseek:     https://api-docs.deepseek.com/quick_start/pricing（DeepSeek 官方直连价）
#   glm-coding-plan: https://docs.bigmodel.cn/cn/coding-plan/overview（智谱官方定价，未订阅/近似值）
#
# 上下文窗口（2026-06-27 官方文档验证）：
#   deepseek-v4-*   https://api-docs.deepseek.com/quick_start/pricing        → 1,000,000
#   qwen3.7-*       https://www.alibabacloud.com/help/en/model-studio/       → 1,000,000
#   qwen3.6-plus    https://www.alibabacloud.com/help/en/model-studio/       → 1,000,000
#   glm-5.2         https://bigmodel.cn/glm-coding                                         → 1,000,000
#   glm-5.1         https://docs.bigmodel.cn/                                              →   200,000
#   kimi-k2.*       https://platform.moonshot.cn/docs/                       →   256,000
#   minimax-m3      https://platform.minimaxi.com/docs/                      → 1,000,000
#   minimax-m2.7    https://platform.minimaxi.com/docs/                      →   204,800
#   mimo-v2.5*      OpenRouter/HuggingFace card                              → 1,000,000

{ lib }:

let
  ## 模型构造器 — 强制每个模型声明 cost，可选 contextWindow/extra_body
  ## 价格单位：$/1M tokens，上下文窗口单位：tokens
  ## extra_body: LiteLLM 透传字段（绕过适配层，源码：llm_http_handler.py:448-449）
  ##   用途：禁用 DeepSeek V4 思考模式等适配层 bug 场景
  ##
  ## reasoning: 是否支持 reasoning（OpenCode variant 选择器的门控，transform.ts:666）
  ## reasoningEfforts: 模型支持的可控 effort 列表（null=无 effort 控制能力）
  ##   Codex 据此生成 supported_reasoning_levels
  ##   来源（2026-06-29 官方文档验证）：
  ##     deepseek-v4: https://api-docs.deepseek.com/guides/thinking_mode → high, max
  ##     kimi-k2.7-code: https://platform.kimi.com/docs/guide/use-kimi-k2-thinking-model → 始终思考，无 effort 参数
  ##     kimi-k2.6: 同上 → toggle only (enabled/disabled)，无 effort 粒度
  ##     qwen3.*: 无 reasoning_effort API 端点（opencode transform.ts:711 明确排除）
  ##     minimax-m3: thinking adaptive toggle（opencode transform.ts:672-679 显式处理）
  ##     glm-5.2: opencode transform.ts:690-694 显式处理 high/max
  mkModel =
    {
      input,
      output,
      cache_read ? 0,
      cache_write ? 0,
      contextWindow ? null,
      extra_body ? null,
      reasoning ? false,
      reasoningEfforts ? null,
    }:
    {
      cost = {
        inherit
          input
          output
          cache_read
          cache_write
          ;
      };
      inherit
        contextWindow
        extra_body
        reasoning
        reasoningEfforts
        ;
    };

  ## Provider 注册表
  providers = {
    # OpenCode Go — $10/月，13 个开源模型，$60 月额度
    # 仅 OpenAI Chat Completions 端点
    # 定价与直连 API 不同（Go 有加价），以下为 Go 官方定价
    # 模型列表 + 定价文档：https://opencode.ai/docs/zh-cn/go
    # 检查模型：curl -s https://opencode.ai/zen/go/v1/models | jq '[.data[].id]'
    opencode-go = {
      openai_url = "https://opencode.ai/zen/go/v1";
      key_ref = "opencode-go-key";
      models = {
        "glm-5.2" = mkModel {
          input = 1.40;
          output = 4.40;
          cache_read = 0.26;
          contextWindow = 1000000; # 官方宣传 1M 上下文（bigmodel.cn/glm-coding）
          reasoning = true;
          reasoningEfforts = [
            "high"
            "max"
          ];
        };
        "glm-5.1" = mkModel {
          input = 1.40;
          output = 4.40;
          cache_read = 0.26;
          contextWindow = 200000;
          # 无 reasoning_effort API（opencode transform.ts:708 排除）
        };
        "kimi-k2.7-code" = mkModel {
          input = 0.95;
          output = 4.00;
          cache_read = 0.19;
          contextWindow = 256000;
          # 始终思考，无 effort 参数（kimi-k2.7-code 不支持 reasoning_effort）
        };
        "kimi-k2.6" = mkModel {
          input = 0.95;
          output = 4.00;
          cache_read = 0.16;
          contextWindow = 256000;
          # 仅 thinking toggle (enabled/disabled)，无 effort 粒度
        };
        "mimo-v2.5" = mkModel {
          input = 0.14;
          output = 0.28;
          cache_read = 0.0028;
          contextWindow = 1000000;
          reasoning = true;
          reasoningEfforts = [
            "low"
            "medium"
            "high"
          ];
        };
        "mimo-v2.5-pro" = mkModel {
          input = 1.74;
          output = 3.48;
          cache_read = 0.0145;
          contextWindow = 1000000;
          reasoning = true;
          reasoningEfforts = [
            "low"
            "medium"
            "high"
          ];
        };
        "minimax-m3" = mkModel {
          input = 0.30;
          output = 1.20;
          cache_read = 0.06;
          contextWindow = 1000000;
          reasoning = true;
          # MiniMax-M3 通过 thinking type 控制：disabled=关 / adaptive=开
          # opencode transform.ts:672-679 显式处理为 none/thinking
          # Codex 映射：none=thinking disabled, medium=thinking adaptive
          reasoningEfforts = [
            "none"
            "medium"
          ];
        };
        "minimax-m2.7" = mkModel {
          input = 0.30;
          output = 1.20;
          cache_read = 0.06;
          cache_write = 0.375;
          contextWindow = 204800;
          # 无 reasoning_effort API（opencode transform.ts:707 排除）
        };
        "qwen3.7-max" = mkModel {
          input = 2.50;
          output = 7.50;
          cache_read = 0.50;
          cache_write = 3.125;
          contextWindow = 1000000;
          # 无 reasoning_effort API（opencode transform.ts:711 排除）
        };
        "qwen3.7-plus" = mkModel {
          input = 0.40;
          output = 1.60;
          cache_read = 0.04;
          cache_write = 0.50;
          contextWindow = 1000000;
          # 无 reasoning_effort API（opencode transform.ts:711 排除）
        };
        "qwen3.6-plus" = mkModel {
          input = 0.50;
          output = 3.00;
          cache_read = 0.05;
          cache_write = 0.625;
          contextWindow = 1000000;
          # 无 reasoning_effort API（opencode transform.ts:711 排除）
        };
        "deepseek-v4-pro" = mkModel {
          input = 1.74;
          output = 3.48;
          cache_read = 0.0145;
          contextWindow = 1000000;
          reasoning = true;
          # DeepSeek V4 reasoning_effort（官方文档 26-06-29）：
          #   high: 默认值（regular requests），max: 最高 effort（Agent 请求自动触发）
          #   low/medium 静默映射→high, xhigh→max
          reasoningEfforts = [
            "high"
            "max"
          ];
          # DeepSeek V4 思考模式参数（官方文档 26-06-29）：
          #   - thinking 默认 enabled，reasoning_content 与 content 同级返回
          #   - Agent 请求（Claude Code/OpenCode/Codex）自动 effort=max
          #   - effort=max 时简单问题也消耗 400+ token 思考
          #   - 客户端 max_tokens 较小（200-500）时 reasoning 耗尽 → content 为空
          # 方案：保留 thinking=enabled（不阉割模型能力），
          #       通过 reasoning_effort=high 覆盖 Agent 自动 max，
          #       降为普通请求默认值（与直连 API 普通请求一致）。
          # LiteLLM 1.89.0 适配层 bug：reasoning_effort 被 pop 丢弃
          # (transformation.py:49-63)，必须用 extra_body 绕过。
          extra_body.thinking.type = "enabled";
          extra_body.reasoning_effort = "high";
        };
        "deepseek-v4-flash" = mkModel {
          input = 0.14;
          output = 0.28;
          cache_read = 0.0028;
          contextWindow = 1000000;
          reasoning = true;
          reasoningEfforts = [
            "high"
            "max"
          ];
          extra_body.thinking.type = "enabled";
          extra_body.reasoning_effort = "high";
        };
      };
    };

    # DeepSeek API — 按量计费（直连 API，非 Go 套餐加价）
    # Anthropic + OpenAI 双端点直连
    # 文档：https://api-docs.deepseek.com/quick_start/pricing
    deepseek = {
      anthropic_url = "https://api.deepseek.com/anthropic";
      openai_url = "https://api.deepseek.com";
      key_ref = "deepseek-key";
      models = {
        "deepseek-v4-pro" = mkModel {
          input = 0.435;
          output = 0.87;
          cache_read = 0.003625; # 官方文档 cache hit 价格
          contextWindow = 1000000;
          reasoning = true;
          reasoningEfforts = [
            "high"
            "max"
          ];
          extra_body.thinking.type = "enabled";
          extra_body.reasoning_effort = "high";
        };
        "deepseek-v4-flash" = mkModel {
          input = 0.14;
          output = 0.28;
          cache_read = 0.0028; # 官方文档 cache hit 价格
          contextWindow = 1000000;
          reasoning = true;
          reasoningEfforts = [
            "high"
            "max"
          ];
          extra_body.thinking.type = "enabled";
          extra_body.reasoning_effort = "high";
        };
      };
    };

    # GLM Coding Plan — 智谱 GLM-5.2，双端点直连
    # 套餐：Lite ¥49/月 | Pro ¥149/月 | Max ¥200/月
    # 文档：https://docs.bigmodel.cn/cn/coding-plan/overview
    glm-coding-plan = {
      anthropic_url = "https://open.bigmodel.cn/api/anthropic";
      openai_url = "https://open.bigmodel.cn/api/coding/paas/v4";
      key_ref = "glm-coding-plan-key";
      models = {
        "glm-5.2" = mkModel {
          input = 1.40;
          output = 4.40;
          contextWindow = 1000000; # 官方宣传 1M 上下文
          reasoning = true;
          reasoningEfforts = [
            "high"
            "max"
          ];
        };
      };
    };
  };
in
{
  inherit providers;
}
