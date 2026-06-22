# ollama

## Architecture

```
NixOS declarative model management
  loadModels = [ "qwen3.6:27b-q4_K_M" ]  →  ollama-model-loader.service (oneshot)
  syncModels = true                        →  removes undeclared models

ollama.service
  User=ollama (static, not DynamicUser)
  host=0.0.0.0:11434  →  firewall收口到 tailscale0
  GPU: RTX 5090 (32GB VRAM)
```

## Decisions

| Decision | Rationale |
|----------|-----------|
| `loadModels` + `syncModels` | 声明式模型管理。NixOS 可复现性:配置==实际状态。替代命令式 `ollama pull` |
| 静态用户 `ollama`(非 DynamicUser) | btrfs 子卷 `/var/lib/ollama` 需要 chown,DynamicUser 每次启动 UID 变化无法持久化 |
| `host = "0.0.0.0"` | 监听所有接口,靠 `firewall.interfaces.tailscale0` 收口到 tailnet |
| `OLLAMA_FLASH_ATTENTION = "1"` | KV cache 量化的前置条件。Flash Attention 减少内存访问,提升推理速度 |
| `OLLAMA_KV_CACHE_TYPE = "q8_0"` | 8-bit KV cache,内存减半,近无损(PPL +0.002-0.05)。2026 官方推荐安全默认 |
| `OLLAMA_CONTEXT_LENGTH = "262144"` | 256K,Qwen3.6 原生上限。配合 q8_0 量化控制 KV cache 内存 |
| `OLLAMA_KEEP_ALIVE = "30m"` | 避免空闲模型反复加载/卸载,降低延迟 |
| `OLLAMA_MAX_LOADED_MODELS = "1"` | 32GB VRAM 只够一个 27B Q4_K_M + 256K KV cache |
| `CUDA_VISIBLE_DEVICES = "0"` | 只使用 dGPU(PCI:1@0:0:0),iGPU 留给桌面 |
| `OLLAMA_ORIGINS = "*"` | tailnet 内可信,允许跨域访问(MCP 集成) |

## Source of truth

`hosts/desktop-1/default.nix` L75-92
