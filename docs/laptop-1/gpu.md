# GPU — laptop-1

> GTX 950M (Maxwell GM107) + Intel HD 530 · PRIME offload · Wayland only

## 架构

```
Intel HD 530 (iGPU)  ←── eDP-1 显示器 ──→ River compositor, 日常桌面
NVIDIA GTX 950M (dGPU) ←── nvidia-offload ──→ CUDA, NVENC, 按需计算
```

## 决策

| 决策 | 理由 |
|------|------|
| `legacy_580` 而非 `stable` | Maxwell 在 nixpkgs stable (595.84) 中已移除。580 系列是 Maxwell/Pascal/Volta 最后分支 (Phoronix 2025-07-01) |
| PRIME offload 而非 sync | **Wayland 不支持 PRIME sync 模式** (X11-only)。offload 模式：iGPU 驱屏，dGPU 按需调用 |
| `open = false` | Maxwell 不支持 nvidia-open kernel module（仅 Turing+ 支持） |
| `powerManagement.finegrained = false` | Maxwell 不支持精细电源管理（仅 Turing+ 支持） |
| `modprobe.blacklist=nouveau` + `nouveau.modeset=0` (kernel params) | `boot.blacklistedKernelModules` 仅在 modprobe.d 层面黑名单，不阻止 udev 硬件检测自动加载 nouveau。须在内核启动时就禁用 |
| `nvidia-drm.modeset=1` | Wayland 需要 KMS；虽然 iGPU 驱动显示，但 PRIME offload 仍需 nvidia-drm |
| `services.xserver.videoDrivers = ["nvidia"]` | **必需**：触发 `hardware.nvidia` 模块激活 + 安装 GSP 固件到 `/lib/firmware/nvidia/`。不设置会导致 `RmInitAdapter failed` |

## 与 desktop-1 对比

| 项目 | laptop-1 | desktop-1 |
|------|------|------|
| dGPU | GTX 950M (Maxwell) | RTX 5090 (Blackwell) |
| 驱动 | legacy_580 (闭源) | stable (nvidia-open) |
| Compute Capability | 5.0 | 12.0 |
| CUDA | 12.x (13.0+ 不支持 SM 5.x) | 13.x |
| NVENC | H.264 only (4th Gen) | H.264 + H.265 + AV1 (9th Gen) |
| VRAM | 2GB | 32GB |
| 用途 | 按需 CUDA / NVENC 视频编码 | Ollama LLM 推理 + CUDA 计算 |
| PRIME 模式 | offload (Wayland 仅此选项) | offload (同) |
