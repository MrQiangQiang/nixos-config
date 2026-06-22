# VRAM allocation

## Architecture

```
NixOS declarative model management
  loadModels = [ "qwen3.6:27b-q4_K_M" ]  →  ollama-model-loader.service (oneshot, download only)
  syncModels = true                        →  removes undeclared models
  custom.ollama.enable = true              →  modules/ollama.nix (options + prewarm)

ollama.service (system service, starts first)
  User=ollama (static, not DynamicUser)
  host=0.0.0.0:11434  →  firewall收口到 tailscale0
  GPU: RTX 5090 (32GB VRAM)
  ├── ollama qwen3.6:27b-q4_K_M  27.7GB  (权重 17GB + KV cache 10.7GB, 256K context)
  └── qmd (embed + rerank + generate)  ~2.2GB  (剩余 4.3GB 中的部分)

ollama-prewarm.service (after ollama.service)
  → 发送推理请求触发 VRAM 加载 (loadModels 只下载不加载)
```

## Decisions

| Decision | Rationale |
|----------|-----------|
| `loadModels` + `syncModels` | 声明式模型管理。NixOS 可复现性:配置==实际状态。替代命令式 `ollama pull` |
| 静态用户 `ollama`(非 DynamicUser) | btrfs 子卷 `/var/lib/ollama` 需要 chown,DynamicUser 每次启动 UID 变化无法持久化 |
| `host = "0.0.0.0"` | 监听所有接口,靠 `firewall.interfaces.tailscale0` 收口到 tailnet |
| `OLLAMA_KEEP_ALIVE=-1` | 模型永不卸载，杜绝 qmd 抢占 VRAM 后 ollama 降级。专用 LLM 服务器标准配置 |
| `ollama-prewarm.service` | `loadModels` 只下载模型到磁盘，不加载到 VRAM。本服务在 ollama 启动后发送推理请求触发 VRAM 加载 |
| `OLLAMA_CONTEXT_LENGTH=262144` | qwen3.6 原生 256K 上下文。ollama 按 `OLLAMA_CONTEXT_LENGTH` 预分配 KV cache（非实际使用量） |
| `OLLAMA_FLASH_ATTENTION=1` | KV cache 量化的前置条件。Flash Attention 减少内存访问，提升推理速度 |
| `OLLAMA_KV_CACHE_TYPE=q8_0` | 8-bit KV cache，质量不降低（实测略高于 FP16），VRAM 占用减半 |
| `OLLAMA_MAX_LOADED_MODELS = "1"` | 32GB VRAM 只够一个 27B Q4_K_M + 256K KV cache |
| `CUDA_VISIBLE_DEVICES = "0"` | 只使用 dGPU(PCI:1@0:0:0),iGPU 留给桌面 |
| `OLLAMA_ORIGINS = "*"` | tailnet 内可信,允许跨域访问(MCP 集成) |
| ollama 先于 qmd 启动 | systemd 默认：系统服务（ollama）先于用户服务（qmd-mcp）。ollama 先占坑 VRAM，qmd 只能用剩余 |
| `QMD_LLAMA_GPU=cuda` | qmd 使用 node-llama-cpp 自动检测剩余 VRAM，不会抢占 ollama 已分配的显存 |

## 为什么不用手动管理

手动管理（发现 ollama 慢了再检查）无法保证永不降级：qmd 可能先启动抢占 VRAM，导致 ollama 重新加载时降级。自动预加载 + 永久驻留是唯一可靠方案。

## CUDA context 与模型加载

ollama 服务启动即创建 CUDA context（GPU 功耗 ~20W → ~50-90W DVFS 跳变）。模型加载到 VRAM 几乎不增加功耗（<0.02 W/GB）。模型常驻 VRAM 不影响显存寿命（GDDR6 是易失性内存，无写入次数限制）。

## Source of truth

- `modules/ollama.nix` — ollama 模块（options + prewarm service）
- `hosts/desktop-1/default.nix` — `custom.ollama.enable = true`
- `home/dev/qmd.nix` — `QMD_LLAMA_GPU=cuda`
- `home/dev/opencode.nix` — `context = 262144`
