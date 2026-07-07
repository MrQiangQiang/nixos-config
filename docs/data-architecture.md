# 数据架构

## 三层架构

```
git        → 代码 + 文本数据 (nixos-config, projects, knowledge, passwords)
git-annex  → 大文件 (photos, videos, music)
Tailscale  → 网络 (mesh VPN, MagicDNS)
```

## 存储职责

```
desktop-1:
  NVMe 2TB  → 系统、/home、/nix、ollama 模型、qmd 索引 (低延迟)
  HDD 1TB   → /data/annex/ git-annex canonical 仓库 (容量优先, btrfs, nofail)
  GitHub    → MrQiangQiang/annex (仅元数据备份, 不存内容)

laptop-N:
  ~/annex/  → git clone (仅元数据 + symlinks, 无实际内容, group=manual)
```

HDD 而非 SSD 存放大文件:职责清晰,媒体文件不需要低延迟,页面缓存使二次访问等同 SSD 速度。

## git-annex 核心

desktop-1 `/data/annex/` 是唯一 canonical 仓库,所有大文件内容唯一存放地。

```
numcopies = 1  (全局期望副本数)
mincopies = 1  (全局硬底线)
required = "present"  (HDD 内容受保护, 普通 drop 拒绝, 需 --force)
```

numcopies=1:目标是容量管理 + 跨机分发,不是 3-2-1 备份。HDD 的 required="present" 确保内容不被普通操作删除。

不用冷热迁移:preferred content 调参增加隐性复杂度,两个阈值不同步时出现意外行为。所有文件在 HDD 一处,不需要搬来搬去。

## 跨主机同步

```
desktop-1 (canonical, 7x24) ─── git ─── GitHub (远程备份: 文本 + annex 元数据)
    │
    │  SSH/Tailscale (annex 内容按需拉取 + 元数据 sync)
    │
    └── 非 desktop-1 主机 (消费者)
```

两条链路职责分离:
- desktop-1 ↔ GitHub:git push/pull,desktop-1 是唯一对 GitHub 读写的主机
- desktop-1 ↔ 非 desktop-1 主机:annex 内容(get/drop) + 元数据(sync),via Tailscale SSH

非 desktop-1 主机不直连 GitHub:元数据通过 desktop-1 中转,内容只能从 desktop-1 拉取。

### 数据分类与同步方式

| 数据类型 | 同步方式 | 理由 |
|----------|----------|------|
| 代码 + 项目文档 | git + GitHub | 行业标准 |
| 知识库 (markdown) | git only | 版本历史 + 冲突解决 + 人类审查 agent 修改 |
| 密码库 (passage + age) | git only | age 加密设计上允许密文推 GitHub |
| dotfiles / AI 配置 | git only | 已在 nixos-config 仓库 (home-manager 声明式) |
| 大媒体 (照片/视频) | git-annex | partial checkout 适合低配 laptop; 可释放空间 |
| 浏览器书签 | Firefox Sync | places.sqlite 是活跃 SQLite, git/annex 会损坏 |

### 为什么不用 Syncthing

git + Syncthing 双通道是反模式(Syncthing 论坛维护者明确反对混用)。git 提供版本历史、merge 冲突解决、diff 强制人类审查。Syncthing 的 `.sync-conflict` 文件比 git merge 更难处理。一个工具比两个简单。

## 自动化架构

三个 git-annex 操作分属系统层和用户层:

| 操作 | 层级 | 主机 | WHY |
|------|------|------|-----|
| init | system | desktop-1 | 需要 root chown /data/annex (nofail 挂载时序不可靠) |
| sync | user | 非 desktop-1 | 用户操作 ~/annex,无需 root;system service 的 `systemctl start` 触发 polkit `auth_admin_keep`,非交互环境 25s 超时 |
| backup | system | desktop-1 | 依赖 init.service;user manager 与 system manager 完全隔离,user service 无法声明 `After=system-service` |

`linger=true` (modules/users.nix) 确保 user timer 在未登录时仍运行。

## 数据保护策略

当前架构是**数据主仓库 + 文本版本控制**,不是 3-2-1 备份策略。

- 文本数据:NVMe + GitHub = 2 副本 2 介质 1 异地,git 提供版本历史
- 二进制数据:HDD = 1 副本 1 介质 0 异地
- HDD 是 git-annex 数据主仓库,不是备份介质

btrfs 快照不是备份:CoW 与原始数据在同一物理磁盘,磁盘故障会同时丢失数据和快照。

### 当前权衡

- 文本数据优先级最高:已有 NVMe + GitHub 双副本 + git 版本历史
- 二进制数据可替代:照片/视频丢失风险可接受(个人场景)
- 符合低复杂度目标:不引入 restic/OSS/btrbk 等额外工具

### 已知缺口

二进制数据只有 1 份副本,无异地备份。如果未来需要保护:
- 方案 A:git-annex numcopies=2 (HDD + 第二块盘各一份)
- 方案 B:restic + 云存储(异地备份,增加密钥/定时/恢复测试复杂度)
- 方案 C:git-annex 多 remote(HDD + 外置硬盘 + 云,按需)

当前选择:不补充,接受二进制数据单副本风险。

GitHub 仓库 `MrQiangQiang/annex` 仅备份 git-annex branch(元数据:文件名、目录结构、位置日志),**不备份大文件内容**。价值:NVMe 系统盘故障时恢复元数据;HDD 故障时内容仍丢失。

## 数据完整性

- `services.smartd` — SMART 早期故障预警(NVMe + HDD)
- `services.btrfs.autoScrub` — 每月检查 btrfs 数据完整性(NVMe + HDD)
- HDD `nofail` — 故障时不阻塞启动
