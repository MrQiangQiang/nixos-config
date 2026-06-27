# LiteLLM — 本地 LLM 代理网关
#
# 统一入口 (localhost:4000)，所有 AI 工具通过代理访问全部后端：
#   - opencode-go 套餐（$10/月，13 模型）
#   - DeepSeek API（按量计费）
#   - GLM Coding Plan（未来）
#   - Ollama 本地模型
#
# 三协议支持：
#   /v1/messages          → Anthropic Messages（Claude Code）
#   /v1/chat/completions  → OpenAI Chat（OpenCode）
#   /v1/responses         → OpenAI Responses（Codex）
#
# 协议转换：LiteLLM 自动处理 Anthropic↔Chat 和 Responses↔Chat 转换，
# 所有模型对所有工具可见。
#
# 参考：qmd.nix systemd user service 模式
{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  api = import ../agents/api-providers.nix { inherit lib; };

  # Provider 到环境变量映射
  providerEnvKeys = {
    opencode-go = "OPENCODE_GO_KEY";
    deepseek = "DEEPSEEK_KEY";
    glm-coding-plan = "GLM_CODING_PLAN_KEY";
  };

  # 从 api-providers.nix SSOT 生成 model_list
  # 每个 provider 的每个模型生成一个 entry
  modelList = lib.concatLists (
    lib.mapAttrsToList (
      providerName: provider:
      let
        envKey = providerEnvKeys.${providerName};
        apiBase = provider.openai_url or provider.anthropic_url;
      in
      lib.mapAttrsToList (modelName: _modelMeta: {
        model_name = "${providerName}/${modelName}";
        litellm_params = {
          model = "openai/${modelName}";
          api_base = apiBase;
          api_key = "os.environ/${envKey}";
        };
      }) provider.models
    ) api.providers
  );

  # Ollama 本地模型（SSOT: modules/ollama.nix → osConfig.custom.ollama.model）
  ollamaModel = lib.attrByPath [ "custom" "ollama" "model" ] "qwen3.6:27b-q4_K_M" osConfig;
  ollamaModels = [ ollamaModel ];

  # Ollama model_list entries
  ollamaModelList = map (m: {
    model_name = "ollama/${m}";
    litellm_params = {
      model = "openai/${m}";
      api_base = "http://localhost:11434/v1";
      api_key = "placeholder";
    };
  }) ollamaModels;

  # 完整的 LiteLLM YAML 配置
  litellmConfig = {
    model_list = modelList ++ ollamaModelList;

    litellm_settings = {
      drop_params = true;
    };

    general_settings = {
      master_key = "os.environ/LITELLM_MASTER_KEY";
    };
  };

  configYaml = pkgs.formats.yaml { };
  configFile = configYaml.generate "litellm-config.yaml" litellmConfig;

  # agenix 密钥路径
  goKeyPath = osConfig.age.secrets."opencode-go-key".path;
  deepseekKeyPath = osConfig.age.secrets."deepseek-key".path;
  hasGptKey = osConfig.age.secrets ? "glm-coding-plan-key";
  gptKeyPath = if hasGptKey then osConfig.age.secrets."glm-coding-plan-key".path else null;
in
{
  # LiteLLM 配置文件（只读 symlink 到 Nix store）
  home.file.".config/litellm/config.yaml".source = configFile;

  # 环境变量文件（密钥从 agenix 读取，不写入 Nix store）
  # 每次 home-manager switch 时更新
  home.activation.litellmEnv = lib.hm.dag.entryAfter [ "agenixInstall" ] ''
    run mkdir -p $HOME/.config/litellm
    printf 'OPENCODE_GO_KEY=%s\n' "$(cat ${goKeyPath} 2>/dev/null || echo PLACEHOLDER)" > $HOME/.config/litellm/env
    printf 'DEEPSEEK_KEY=%s\n' "$(cat ${deepseekKeyPath} 2>/dev/null || echo PLACEHOLDER)" >> $HOME/.config/litellm/env
    ${lib.optionalString hasGptKey ''
      printf 'GLM_CODING_PLAN_KEY=%s\n' "$(cat ${gptKeyPath} 2>/dev/null || echo PLACEHOLDER)" >> $HOME/.config/litellm/env
    ''}
    printf 'LITELLM_MASTER_KEY=litellm-local\n' >> $HOME/.config/litellm/env
    chmod 600 $HOME/.config/litellm/env
  '';

  # Systemd user service — 本地代理网关，监听 127.0.0.1:4000
  # LiteLLM 单进程运行，不需要 Redis/PostgreSQL
  systemd.user.services.litellm = {
    Unit = {
      Description = "LiteLLM proxy — LLM gateway (localhost:4000)";
      After = [ "network.target" ];
    };
    Service = {
      ExecStart = "${pkgs.litellm}/bin/litellm --config %h/.config/litellm/config.yaml --host 127.0.0.1 --port 4000";
      EnvironmentFile = "%h/.config/litellm/env";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
