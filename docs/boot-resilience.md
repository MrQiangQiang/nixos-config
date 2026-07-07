# Boot Resilience

## 架构决策

| 设置 | 位置 | 层级 | 理由 |
|------|------|------|------|
| `timeout=3` `editor=true` `configurationLimit=10` | `lib/mkHost.nix` | 系统层 / 所有主机共享 | 所有物理机都需要启动恢复能力 |
| `i915.enable_psr=0` | `hosts/laptop-1/default.nix` | 硬件层 / 单主机 | 见下方决策 |

### 为什么 i915 放主机层不放共享层

Skylake 特有缺陷，未来新主机不需要。放 `hosts/laptop-1/` 而非 `modules/` 确保不污染其他主机。

### 为什么 boot.loader 放共享层

`timeout` / `editor` / `configurationLimit` 是物理机安全基线，所有主机都需要。

### 为什么不回滚 flake.lock

i915 fix 针对新内核。回滚 lock = 永远停在旧 nixpkgs，放弃安全更新。正确做法：保持 lock + 加 fix + rebuild。

### 为什么继续用 nixos-unstable 而非稳定频道

unstable 提供最新内核和软件包，代价是 flake update 有回归风险。i915 fix + boot loader 安全网已将风险降至可接受。若未来频繁出问题再切稳定频道。

## 根因

nixos-unstable `flake update` 升级内核 (6.18.33→6.18.34)，Skylake HD 530 的 i915 驱动 RC6/PSR 电源管理触发 KMS 初始化死锁 → 卡 OEM logo → 无 TTY。

参考: https://static.vivaolinux.com.br/dica/Travamentos-completos-no-Linux-com-Intel-HD-520530-Skylake-solucao-definitiva/

## 参数演进

初始 workaround 同时禁用 `enable_rc6`/`enable_psr`/`powersave` 三个参数。内核 6.18+ 移除了 `enable_rc6` 和 `powersave` 模块参数(`/sys/module/i915/parameters/` 不再列出,日志报 `unknown parameter ignored`),仅 `enable_psr` 仍有效。当前配置只保留 `enable_psr=0`,死锁问题未复发。
