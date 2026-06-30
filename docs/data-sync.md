# 跨主机数据同步架构

## 核心架构

```
desktop-1 (canonical, 7x24) ─── git ─── GitHub (远程备份: 文本 + annex 元数据)
    │
    │  SSH/Tailscale (annex 内容按需拉取 + 元数据 sync)
    │
    └── 非 desktop-1 主机 (laptop-N, desktop-2..N, 消费者)
```

两条链路职责分离:
- desktop-1 ↔ GitHub: git push/pull,desktop-1 是唯一对 GitHub 读写的主机
- desktop-1 ↔ 非 desktop-1 主机: annex 内容(get/drop) + 元数据(sync),via Tailscale SSH

## git-annex 跨机同步

单一 canonical 仓库: desktop-1 `/data/annex/` (HDD, btrfs)。详见 [data-storage.md](data-storage.md)。

GitHub 仓库 `MrQiangQiang/annex` 仅作为**元数据备份**(main + git-annex branch),
不存大文件内容(GitHub 不允许)。价值:NVMe 系统盘故障时恢复元数据;HDD 故障时内容仍丢失。

非 desktop-1 主机不直连 GitHub:元数据通过 desktop-1 中转,内容只能从 desktop-1 拉取。

## 数据分类与同步方式

| 数据类型 | 同步方式 | 理由 |
|----------|----------|------|
| 代码 + 项目文档 | git + GitHub | 行业标准 |
| 知识库 (markdown) | git only | 版本历史 + 冲突解决 + 人类审查 agent 修改 |
| 密码库 (passage + age) | git only | age 加密设计上允许密文推 GitHub |
| dotfiles / AI 配置 | git only | 已在 nixos-config 仓库 (home-manager 声明式) |
| 大媒体 (照片/视频) | git-annex | partial checkout 适合低配 laptop; 可释放空间 |
| 浏览器书签 | Firefox Sync | places.sqlite 是活跃 SQLite, git/annex 会损坏 |

## 为什么不用 Syncthing

- **git + Syncthing 双通道是反模式** — Syncthing 论坛维护者 martinleben 明确反对混用
- git 提供版本历史 (rollback agent 写错的 wiki)、merge 冲突解决 (markdown 文本合并好)、diff 强制人类审查
- Syncthing 的 `.sync-conflict` 文件比 git merge 更难处理
- age 加密设计上就允许密文落在不可信介质 (GitHub) 上, 不需要 Syncthing 实时同步
- 一个工具比两个简单 (不需要 .stignore 排除 .git/)

## 唯一来源验证

desktop-1 在所有数据类型上都是唯一来源:
- 代码: git 仓库本地副本 + push 源 (GitHub 是远程备份)
- 知识库: ~/knowledge/ 主副本 + qmd 搜索主实例
- 密码: passage store 主副本 (git 同步)
- 大媒体: /data/annex/ 唯一 canonical 仓库 (HDD, group=backup, required="present")
- AI 配置: nixos-config flake 主副本
- 个人仓库: repos.nix SSOT, home-manager activation 自动 clone
