# Claude Code — Anthropic 的终端编码 agent
#
# 通过 LiteLLM 代理 (localhost:4000) 访问全部后端模型
# 免登录：hasCompletedOnboarding=true 跳过 OAuth 引导
#
# 模型命名（对应 LiteLLM model_name）：
#   opencode-go/glm-5.2  → Go 套餐（GLM/Kimi/DeepSeek/MiniMax/Qwen）
#   deepseek/deepseek-v4-pro → DeepSeek API
#   ollama/qwen3.6:27b-q4_K_M → 本地 Ollama
#
# 切换模型：在 Claude Code 中 /model <name> 或通过 ANTHROPIC_DEFAULT_* 环境变量
{
  lib,
  ...
}:
let
  shared = import ../agents/shared.nix { inherit lib; };
in
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    settings = {
      env = {
        ANTHROPIC_BASE_URL = "http://localhost:4000";
        ANTHROPIC_API_KEY = "litellm-local";
        ANTHROPIC_DEFAULT_SONNET_MODEL = "opencode-go/deepseek-v4-pro";
        ANTHROPIC_DEFAULT_HAIKU_MODEL = "opencode-go/deepseek-v4-flash";
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
}
