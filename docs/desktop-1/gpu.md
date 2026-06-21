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
| `boot.extraModulePackages = [ .open ]` | Kernel module sub-derivation, not full x11 package |
| blacklist nouveau | kernel param + modprobe.d. Nouveau claims GPU before nvidia loads |
| `nvidia_drm.modeset=1` | Set via `hardware.nvidia.modesetting.enable`; no raw kernel param needed |
| PRIME offload | `nvidia-offload <cmd>` runs single app on 5090. Wayland native |
| `services.xserver.videoDrivers` removed | Dead weight on Wayland. DDX drivers are X11-only |

## Source of truth

`hosts/desktop-1/default.nix` L39-56
