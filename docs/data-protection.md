# 数据保护架构

## 实际架构(非 3-2-1 备份)

当前架构是**数据主仓库 + 文本版本控制**,不是 3-2-1 备份策略。

```
文本数据(代码/知识库/密码/dotfiles):
  NVMe(原始) + GitHub(git push, 异地版本控制)
  → 2 份副本, 2 种介质(SSD + 云), 1 份异地
  → git 提供版本历史, 优于简单副本

二进制数据(大文件/媒体):
  HDD (/data/annex/) — 所有文件内容唯一存放地
  → 1 份副本, 1 种介质, 0 份异地
  → numcopies=1, HDD 受 required="present" 保护

HDD 角色:
  git-annex 数据主仓库, 不是备份介质
  所有大文件内容均在 HDD, 不区分冷热
  SSD 不参与 git-annex (职责: 系统/项目/nix/ollama)
```

## 为什么不叫 3-2-1

3-2-1 要求**同一份数据有 3 份副本**。当前架构:
- 文本数据只有 2 份(NVMe + GitHub)
- 二进制数据只有 1 份(HDD)
- HDD 是 git-annex 大文件数据的主仓库 (受 required="present" 保护)

## 为什么 btrfs 快照不是备份

btrfs 快照是 CoW(Copy on Write), 与原始数据在同一物理磁盘。磁盘故障会同时丢失数据和快照, 不是独立备份。

## 当前可接受的权衡

- **文本数据是优先级最高**: 已有 NVMe + GitHub 双副本 + git 版本历史
- **二进制数据是可替代媒体**: 照片/视频丢失风险可接受(个人场景)
- **符合低复杂度目标**: 不引入 restic/OSS/btrbk 等额外工具

## 已知缺口

二进制数据(大文件)只有 1 份副本, 无异地备份。如果未来需要保护:
- 协议方案 A: git-annex numcopies=2 (HDD + 第二块盘各一份)
- 方案 B: restic + 云存储(异地备份, 增加密钥/定时/恢复测试复杂度)
- 方案 C: git-annex 多 remote(HDD + 外置硬盘 + 云, 按需)

当前选择: 不补充, 接受二进制数据单副本风险。

## 数据完整性监控

- `services.smartd` — SMART 早期故障预警(NVMe + HDD)
- `services.btrfs.autoScrub` — 每月检查 btrfs 数据完整性(NVMe + HDD)
- HDD `nofail` — 故障时不阻塞启动

## 清理策略(modules/analysis.nix)

| 清理对象 | 机制 | 配置 |
|----------|------|------|
| Nix store | nix.gc + nix.optimise | weekly, --delete-older-than 30d |
| /tmp, /var/tmp | systemd-tmpfiles | /tmp 10天, /var/tmp 30天 |
| Docker | docker-prune.timer(条件启用) | 保留 30 天 |

## 源码真理

- `modules/disk-health.nix` — smartd 磁盘健康监测 (所有主机共享)
- `hosts/desktop-1/disk-config.nix` — NVMe + HDD 布局 (/data/annex)
- `hosts/desktop-1/default.nix` — autoScrub
- `modules/analysis.nix` — nix gc + tmpfiles + docker prune
- `modules/git-annex.nix` — git-annex 安装
- `docs/data-storage.md` — 存储架构 (HDD 定位, numcopies 语义)
