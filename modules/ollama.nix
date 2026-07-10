{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.ollama;
in
{
  options.custom.ollama = {
    enable = lib.mkEnableOption "Ollama local LLM inference with CUDA";

    model = lib.mkOption {
      type = lib.types.str;
      default = "qwen3.6:27b-q4_K_M";
      description = "Model to preload into VRAM on startup";
    };

    contextLength = lib.mkOption {
      type = lib.types.int;
      default = 256000;
      description = "Context window size (tokens)";
    };

    gpuDevice = lib.mkOption {
      type = lib.types.str;
      default = "0";
      description = "CUDA_VISIBLE_DEVICES value";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 11434;
      description = "Ollama API server port";
    };
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      user = "ollama"; # 静态用户（btrfs 子卷需要 chown，DynamicUser 不可行）
      group = "ollama";
      host = "0.0.0.0"; # 靠防火墙收口到 tailscale0
      port = cfg.port;
      loadModels = [ cfg.model ]; # 显式锁定量化（NixOS 可复现性）
      syncModels = true; # 强制声明==实际，移除未声明模型
      environmentVariables = {
        OLLAMA_FLASH_ATTENTION = "1"; # KV 量化的前置条件
        OLLAMA_MAX_LOADED_MODELS = "1";
        CUDA_VISIBLE_DEVICES = cfg.gpuDevice;
        OLLAMA_ORIGINS = "*"; # tailnet 内可信

        # ── 上下文窗口与 KV cache 量化 ──
        # ollama 按 OLLAMA_CONTEXT_LENGTH 预分配 KV cache（非实际使用量）
        # KEEP_ALIVE=-1：模型永不卸载，杜绝 qmd 抢占 VRAM 后 ollama 降级
        # 注意：loadModels 只下载模型到磁盘，VRAM 预加载由 ollama-prewarm.service 完成
        OLLAMA_CONTEXT_LENGTH = toString cfg.contextLength;
        OLLAMA_KV_CACHE_TYPE = "q8_0"; # 8-bit KV，质量不降低（实测略高于 FP16）
        OLLAMA_KEEP_ALIVE = "-1"; # 永久驻留 VRAM，专用 LLM 服务器标准配置
      };
    };

    # ── Ollama VRAM 预加载 ─────────────────────────────────────
    # loadModels 只下载模型到磁盘，不加载到 VRAM。
    # 本服务在 ollama 服务启动后发送推理请求，将模型加载到 VRAM 并永久驻留。
    # 保证 ollama 模型始终占坑，qmd 只能使用剩余 VRAM。
    systemd.services.ollama-prewarm = {
      description = "Preload ${cfg.model} into VRAM";
      after = [ "ollama.service" ];
      wants = [ "ollama.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.curl ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = 10;
      };
      script = ''
        # 等待 ollama API 就绪
        for i in $(seq 1 60); do
          if curl -sf http://localhost:${toString cfg.port}/api/tags >/dev/null 2>&1; then
            # 预加载模型到 VRAM：keep_alive=-1（永久驻留）
            curl -sf -X POST http://localhost:${toString cfg.port}/api/generate \
              -d '{"model":"${cfg.model}","prompt":" ","stream":false,"keep_alive":-1,"options":{"num_ctx":${toString cfg.contextLength}}}' \
              >/dev/null 2>&1
            exit 0
          fi
          sleep 1
        done
        echo "ollama not ready after 60s" >&2
        exit 1
      '';
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ cfg.port ];
  };
}
