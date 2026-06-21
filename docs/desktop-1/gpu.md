# gpu

## Architecture

```
iGPU (amdgpu)  ←── 显示器 ──→ River compositor, daily desktop
       │                         PCI:115@0:0:0
       │ PRIME offload
dGPU (nvidia)  ←── Ollama, CUDA, nvidia-offload
                      PCI:1@0:0:0, headless
```

## Decisions

| Decision | Rationale |
|----------|-----------|
| iGPU primary display | Saves ~15W idle. dGPU only wakes for compute |
| nvidia-open 595.80 | Required: Blackwell+ needs open module. Proprietary unsupported |
| `services.xserver.videoDrivers = [ "nvidia" ]` | **必需**：触发 `hardware.nvidia` 模块激活 + 安装 GSP 固件到 `/lib/firmware/nvidia/`。不设置会导致 `RmInitAdapter failed`，GPU 不可用，ollama 回退到 CPU |
| blacklist nouveau | kernel param + modprobe.d. Nouveau claims GPU before nvidia loads |
| `nvidia_drm.modeset=1` | Set via `hardware.nvidia.modesetting.enable`; no raw kernel param needed |
| PRIME offload | `nvidia-offload <cmd>` runs single app on 5090. Wayland native |

## Source of truth

`hosts/desktop-1/default.nix` L37-70

## GSP 固件说明

Blackwell 架构（RTX 5090）**强制要求 GSP（GPU System Processor）固件**，无法禁用。
NixOS nvidia 模块源码（`nixos/modules/hardware/video/nvidia.nix`）：

```nix
nvidiaEnabled = lib.elem "nvidia" config.services.xserver.videoDrivers;
nvidia_x11 = if cfg.enabled then cfg.package else null;
hardware.firmware = lib.optional cfg.gsp.enable nvidia_x11.firmware;
```

不设置 `videoDrivers` → `nvidiaEnabled = false` → `nvidia_x11 = null` → GSP 固件不安装
→ 内核日志 `Direct firmware load for nvidia/595.80/gsp_ga10x.bin failed with error -2`
→ `RmInitAdapter failed! (0x61:0x56:2074)` → GPU 初始化失败 → ollama 回退到 CPU

**注意**：`services.xserver.videoDrivers` 虽然在 X11 命名空间下，但在 Wayland 系统中仍然必需。
它不只控制 DDX 驱动安装，更是 `hardware.nvidia` 模块的激活开关。
