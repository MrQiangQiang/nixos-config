# bios

## Memory

```
EXPO I → DDR5-6000    | 6400 rated kit. 6000 avoids dual-rank IMC instability
UCLK DIV1 → =MEMCLK  | Auto sets 1:2 above ~5800 (igor'LAB). Manual forces 1:1
FCLK → 2000 MHz       | 3000:2000 = 3:2:3 perfect sync
SoC Voltage → Auto    | ~1.15V at 6000; safe. 1.30V ceiling for Zen5
```

## CPU

```
PBO → Advanced        | unlocks power limit editing
PBO Limits → Motherboard | removes 230W PPT cap; thermal-limited instead
Boost Override → +200 | allows single-core 5.9 GHz ceiling
Curve Optimizer       | CCD0 -20, CCD1 -15 (conservative for SP 119)
Scalar → 1x           | keeps FIT protection; 10x only adds heat
Thermal Limit → 90°C  | quieter than default 95°C; no perceptible loss
```

## Platform

```
Primary Video → IGFX  | iGPU drives display; dGPU headless compute
Above 4G Decoding → Enabled | ReBAR prerequisite (verified active)
Resize BAR → Auto     | verified: 32 GiB BAR on RTX 5090
C-states → Enabled    | C6 requires Global + DF C-states both on
Fast Boot → Disabled  | prevents USB/NIC init skips
CSM → Disabled        | pure UEFI
Secure Boot → Other OS | off for NixOS; lanzaboote later
Spread Spectrum → Off | BCLK stability for EXPO/OC
```

## Rationale

Memory 6000 over 6400: 2×48 GiB dual-rank IMC load at 6400 1:1 is unstable for most 9950X (community consensus). 6000 hits the 3:2:3 sweet spot. 6400 could be attempted after system validation.

iGPU primary: RTX 5090 stays in headless compute mode (Ollama, CUDA). `nvidia-offload` runs apps on dGPU on demand. Saves ~15W idle vs dGPU driving display.
