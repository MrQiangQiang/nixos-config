# Claude Code — Anthropic 的终端编码 agent
#
# 通过 LiteLLM 代理 (port via custom.litellm.port) 访问全部后端模型
# 免登录：hasCompletedOnboarding=true 跳过 OAuth 引导
#
# 模型命名（对应 LiteLLM model_name）：
#   opencode-go/glm-5.2  → Go 套餐（GLM/Kimi/DeepSeek/MiniMax/Qwen）
#   deepseek/deepseek-v4-pro → DeepSeek API
#   ollama/qwen3.6:27b-q4_K_M → 本地 Ollama
#
# 切换模型：在 Claude Code 中 /model <name> 或通过 ANTHROPIC_DEFAULT_* 环境变量
{
  config,
  lib,
  pkgs,
  ...
}:
let
  shared = import ../agents/shared.nix { inherit lib pkgs; };
in
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    settings = {
      env = {
        # 后台任务模型（标题生成、statusline-setup 等子 Agent）
        # 暂用 ollama 模型（余额不足），等 OpenCode Go 套餐充值后改回 deepseek-v4-pro
        ANTHROPIC_DEFAULT_SONNET_MODEL = "ollama/qwen3.6:27b-q4_K_M";
        ANTHROPIC_DEFAULT_HAIKU_MODEL = "ollama/qwen3.6:27b-q4_K_M";
        CLAUDE_CODE_ATTRIBUTION_HEADER = "0";
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
      };
    };

    context = shared.combinedContext; # → ~/.claude/CLAUDE.md（常驻上下文，单一入口）
    skills = shared.skills; # → ~/.claude/skills/<name>/SKILL.md
    commands = shared.commands; # → ~/.claude/commands/<name>.md
    agents = shared.agents; # → ~/.claude/agents/<name>.md
  };

  # 跳过 OAuth 登录引导 — 仅首次创建
  home.activation.claudeCodeBypassOnboarding = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.claude.json" ]; then
      $DRY_RUN_CMD echo '{"hasCompletedOnboarding": true}' > "$HOME/.claude.json"
    fi
  '';

  # 启用 LiteLLM 网关模型动态发现（/model 菜单显示所有 LiteLLM 模型）
  # 必须在 Claude Code 启动前设置为系统环境变量，settings.json 的 env 字段不会导出到进程环境
  # 要求 Claude Code v2.1.129+（当前 v2.1.201）
  #
  # 源码分析（v2.1.201 二进制）：
  # - fr() 调用 Xm() 即 jt.gatewayAuth，为空则不返回 "gateway"，discovery 走非 gateway 路径被跳过
  # - fQr() 检查 CLAUDE_CODE_USE_GATEWAY，设置 gatewayAuth={url:ANTHROPIC_BASE_URL, jwt:ANTHROPIC_AUTH_TOKEN}
  # - YAf() 当 fr()==="gateway" 时执行 JAf()，查询 ${ANTHROPIC_BASE_URL}/v1/models
  # - 过滤：只显示以 "claude" 或 "anthropic" 开头的模型 ID（litellm.nix 的 model_group_alias 已添加前缀）
  home.sessionVariables = {
    # 激活 gateway 模式 — 设置 jt.gatewayAuth，使 fr() 返回 "gateway"
    CLAUDE_CODE_USE_GATEWAY = "1";
    # discovery 开关 — 启用 /v1/models 查询
    CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1";
    # gateway 认证 — fQr() 使用此值作为 jwt bearer token
    ANTHROPIC_AUTH_TOKEN = "litellm-local";
    # gateway URL — fQr() 使用此值作为 gateway base URL
    ANTHROPIC_BASE_URL = "http://localhost:${toString config.custom.litellm.port}";
  };
}
