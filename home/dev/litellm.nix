# LiteLLM — 本地 LLM 代理网关
#
# 统一入口 (localhost:4000)，所有 AI 工具通过代理访问全部后端：
#   - opencode-go 套餐（$10/月，14 模型）
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
  # Claude Code 原生 variant 选择（网格 UI，左右键选 effort），无需 litellm 层拆分 variant 条目
  # OpenCode/Codex 各自客户端处理 variant，也无需 litellm 层干预
  # extra_body（如禁用 DeepSeek 思考模式）从模型定义透传到 litellm_params
  modelList = lib.concatLists (
    lib.mapAttrsToList (
      providerName: provider:
      let
        envKey = providerEnvKeys.${providerName};
        apiBase = provider.openai_url or provider.anthropic_url;
      in
      lib.mapAttrsToList (modelName: modelMeta: {
        model_name = "${providerName}/${modelName}";
        litellm_params = {
          model = "openai/${modelName}";
          api_base = apiBase;
          api_key = "os.environ/${envKey}";
          use_chat_completions_api = true;
        }
        // (lib.optionalAttrs (modelMeta.extra_body or null != null) {
          inherit (modelMeta) extra_body;
        });
      }) provider.models
    ) api.providers
  );

  # Ollama 本地模型（SSOT: modules/ollama.nix → osConfig.custom.ollama.model）
  ollamaModel = osConfig.custom.ollama.model;
  ollamaModels = [ ollamaModel ];

  # Ollama 上游：本机启用走 localhost，否则经 tailnet 连 desktop-1（唯一 GPU 服务器）
  ollamaApiBase =
    if osConfig.custom.ollama.enable then "http://localhost:11434/v1" else "http://desktop-1:11434/v1";

  # Ollama model_list entries
  ollamaModelList = map (m: {
    model_name = "ollama/${m}";
    litellm_params = {
      model = "openai/${m}";
      api_base = ollamaApiBase;
      api_key = "placeholder";
    };
  }) ollamaModels;

  # 完整的 LiteLLM YAML 配置
  litellmConfig = {
    model_list = modelList ++ ollamaModelList;

    litellm_settings = {
      drop_params = true;
      # 启用消息净化：自动处理请求侧 orphaned tool_calls / orphaned tool_results / empty content
      # 官方文档：https://docs.litellm.ai/docs/completion/message_sanitization
      # 注意：本字段不修复响应侧 content bug（由下方 LITELLM_USE_CHAT_COMPLETIONS_URL_FOR_ANTHROPIC_MESSAGES 环境变量绕过）
      modify_params = true;
      # 过滤非 function 工具类型（如 Codex Responses API 的 namespace 工具分组）
      # 源码依据：async_pre_call_hook 返回 dict 替换请求体
      #   (litellm/proxy/utils.py:1403-1511 → common_request_processing.py:970)
      # get_instance_fn 相对 config.yaml 目录解析 (types_utils/utils.py:8-65)
      callbacks = [ "litellm_tool_filter.non_function_tool_filter" ];
    };

    general_settings = {
      master_key = "os.environ/LITELLM_MASTER_KEY";
    };
  };

  configYaml = pkgs.formats.yaml { };
  configFile = configYaml.generate "litellm-config.yaml" litellmConfig;

  # 配置目录（config.yaml + callback .py 同目录，get_instance_fn 相对解析）
  # 单一 derivation 保证所有文件来源一致，符合 SSOT 原则
  litellmConfigDir = pkgs.runCommand "litellm-config" { } ''
    mkdir -p $out
    cp ${configFile} $out/config.yaml
    cp ${./litellm/tool-filter.py} $out/litellm_tool_filter.py
  '';

  # LiteLLM 补丁：
  # - responses-fix.patch: 修复 /v1/responses 流式传输时空 choices chunk 导致 IndexError
  #   源码：streaming_iterator.py:1153（1.89.0）/ :1036（>=1.90.0），截至 main cd6e8cd (v1.93.0) 未修复
  # - opencode-go-fix.patch: 修复 Codex Responses→Chat 转换的 messages 格式问题
  #   根因：transformation.py:391-434 只合并 function_call，不合并 message output item
  #   修复：合并连续 assistant message（Go 代理拒绝连续两个 assistant message）
  patchedLitellm = pkgs.litellm.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./litellm/responses-fix.patch
      ./litellm/opencode-go-fix.patch
    ];
  });

  # agenix 密钥路径
  goKeyPath = osConfig.age.secrets."opencode-go-key".path;
  deepseekKeyPath = osConfig.age.secrets."deepseek-key".path;
  hasGptKey = osConfig.age.secrets ? "glm-coding-plan-key";
  gptKeyPath = if hasGptKey then osConfig.age.secrets."glm-coding-plan-key".path else null;
in
{
  # LiteLLM 配置文件 + callback（只读 symlink 到 Nix store）
  # 所有文件必须同目录：get_instance_fn 相对 config.yaml 解析 callback 模块
  home.file.".config/litellm/config.yaml".source = "${litellmConfigDir}/config.yaml";
  home.file.".config/litellm/litellm_tool_filter.py".source =
    "${litellmConfigDir}/litellm_tool_filter.py";

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
      # Restart to apply config.yaml changes
      X-Restart-Triggers = [ "${litellmConfigDir}/config.yaml" ];
    };
    Service = {
      ExecStart = "${patchedLitellm}/bin/litellm --config %h/.config/litellm/config.yaml --host 127.0.0.1 --port 4000";
      EnvironmentFile = "%h/.config/litellm/env";
      # 绕过 LiteLLM 1.89.0 Messages→Chat→Messages 双桥 bug
      # Bug：responses_adapters/transformation.py:415-518 的 isinstance(item, dict)
      # 检查失败（GenericResponseOutputItem 是 Pydantic BaseModel 非 dict），
      # 导致 content 被丢弃为 []。走单桥路径（adapters/transformation.py:1255-1361）
      # 用独立 if 添加 content，不吞掉。截至 main 48b5a5a (2026-06-28) 未修复。
      Environment = [ "LITELLM_USE_CHAT_COMPLETIONS_URL_FOR_ANTHROPIC_MESSAGES=true" ];
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
