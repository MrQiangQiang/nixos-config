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
# 注意：Go 套餐与直连 API 的定价不同（Go 对部分模型有加价），各 provider 使用各自官方定价。

{ lib }:

let
  ## 模型构造器 — 强制每个模型声明 cost，遗漏则构建失败
  ## 价格单位：$/1M tokens
  mkModel = { input, output, cache_read ? 0, cache_write ? 0 }:
    { cost = { inherit input output cache_read cache_write; }; };

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
        "glm-5.2"    = mkModel { input = 1.40; output = 4.40; cache_read = 0.26; };
        "glm-5.1"    = mkModel { input = 1.40; output = 4.40; cache_read = 0.26; };
        "kimi-k2.7-code" = mkModel { input = 0.95; output = 4.00; cache_read = 0.19; };
        "kimi-k2.6"  = mkModel { input = 0.95; output = 4.00; cache_read = 0.16; };
        "mimo-v2.5"  = mkModel { input = 0.14; output = 0.28; cache_read = 0.0028; };
        "mimo-v2.5-pro" = mkModel { input = 1.74; output = 3.48; cache_read = 0.0145; };
        "minimax-m3" = mkModel { input = 0.30; output = 1.20; cache_read = 0.06; };
        "minimax-m2.7" = mkModel { input = 0.30; output = 1.20; cache_read = 0.06; cache_write = 0.375; };
        "qwen3.7-max" = mkModel { input = 2.50; output = 7.50; cache_read = 0.50; cache_write = 3.125; };
        "qwen3.7-plus" = mkModel { input = 0.40; output = 1.60; cache_read = 0.04; cache_write = 0.50; };
        "qwen3.6-plus" = mkModel { input = 0.50; output = 3.00; cache_read = 0.05; cache_write = 0.625; };
        "deepseek-v4-pro" = mkModel { input = 1.74; output = 3.48; cache_read = 0.0145; };
        "deepseek-v4-flash" = mkModel { input = 0.14; output = 0.28; cache_read = 0.0028; };
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
        "deepseek-v4-pro" = mkModel { input = 0.435; output = 0.87; };
        "deepseek-v4-flash" = mkModel { input = 0.14; output = 0.28; };
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
        "glm-5.2" = mkModel { input = 1.40; output = 4.40; };
      };
    };
  };
in {
  inherit providers;
}