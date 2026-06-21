# 数据存储架构

## 核心架构

```
desktop-1:
  /data/annex/                    ← git-annex 仓库 (btrfs on HDD, 1TB)
  │                                 group=backup, required="present"
  ├── photos/                     ← 按类型分子目录 (社区推荐)
  ├── videos/
  ├── music/
  └── documents/

  ~/annex → /data/annex           ← 软链接, 日常浏览用

laptop-N:
  ~/annex/                        ← git clone (仅元数据 + symlinks, 无实际内容)
                                    group=manual
```

## git-annex 单一职责

git-annex 的唯一职责是**管理文件内容在 desktop-1 和 laptop-N 之间的分布**。desktop-1 `/data/annex/` 是 canonical 仓库，所有大文件内容唯一存放地。跨机同步详见 [data-sync.md](data-sync.md)。

## 为什么 HDD 而非 SSD

- **2TB NVMe 职责**: 系统、/home、/nix、ollama 模型、知识库 qmd 索引 — 需要低延迟
- **1TB HDD 职责**: git-annex 大文件存储 — 需要容量，不需要低延迟
- 职责清晰: 每块盘只做一件事，不跨界
- 媒体文件 HDD 顺序读 ~100MB/s: 10MB 照片 <100ms，音乐/视频流无感
- Linux 页面缓存: 二次访问的文件在 RAM 中，等同 SSD 速度
- btrfs autoScrub + smartd 已覆盖 HDD 完整性

## 为什么不用冷热迁移

- 冷热迁移需要 preferred content 调参 (`wanted=smallerthan=100mb` 等), 增加隐性复杂度
- `git annex move --to cold` 后 SSD symlink 变断，sync 行为依赖阈值对齐
- 两个阈值 (迁移决策 / wanted 表达式) 不同步时出现意外行为
- 消除整个"冷热迁移"概念: 所有文件在 HDD 一处，不需要搬来搬去
- 如果将来 HDD 满了: 加第二块盘 + `git annex copy --to new-drive --auto` + `maxsize` (真正的容量扩展, 不涉及迁移语义)

## numcopies/mincopies 语义

```
numcopies = 1  (全局期望副本数)
mincopies = 1  (全局硬底线)

正常状态:
  HDD 有 1 份 → numcopies=1 满足 → 不会告警

laptop 拉取后:
  HDD + laptop = 2 份 → 超出 numcopies, 双方都可 drop

laptop drop 后:
  HDD 有 1 份 → 回归正常

HDD 保护:
  git annex required here "present" → 普通 git annex drop 拒绝删除 HDD 内容
  只有 --force 才能删除 HDD 副本
```

## 为什么 numcopies=1

- 当前架构目标: 容量管理 + 跨机分发，不是 3-2-1 备份
- HDD 的 `required="present"` 确保内容不会被普通操作删除
- 备份方案 (如果需要): 参考 [data-protection.md](data-protection.md) 的已知缺口和未来选项
- Joey Hess 本人对冷存储的做法: 设置 trusted，永不 drop (2022-06-28 forum)

## 初始化步骤 (一次性)

```bash
# desktop-1
mkdir -p /data/annex
cd /data/annex
git init && git annex init "desktop-1"
git annex group here backup
git annex required here "present"
git annex numcopies 1
git annex mincopies 1

# laptop-1
git clone fugui@desktop-1.tail0f7af0.ts.net:/data/annex ~/annex
cd ~/annex
git annex init "laptop-1"
git annex group here manual
```

## 源码真理

- `modules/git-annex.nix` — 安装 git-annex (仅 desktop-1 import)
- `hosts/desktop-1/disk-config.nix` — HDD disk.data (btrfs, /data/annex, nofail)
- `hosts/desktop-1/default.nix` — autoScrub, smartd
- `docs/data-sync.md` — 跨主机同步
- `docs/data-protection.md` — 数据保护
