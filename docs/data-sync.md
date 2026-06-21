# 跨主机数据同步架构

## 核心架构

```
desktop-1 (唯一来源, 7x24) ─── git/GitHub ─── laptop-1 (消费者)
    │                                              │
    │  git push/pull over Tailscale SSH            │  git push/pull
    │  git-annex sync (大文件元数据)                │  git-annex get/drop (按需)
```

## git-annex 跨机同步

git-annex 的职责是**管理文件内容在多个 remote 之间的分布**。本文档描述"跨机同步"用例(desktop-1↔laptop-1),容量扩展用例见 [cold-data-storage.md](cold-data-storage.md)。两个用例是同一职责的不同应用。

desktop-1 有两个 git-annex 仓库(SSD + HDD,见 cold-data-storage.md)。laptop-1 需要访问两者:

```
laptop-1 ~/annex/
├── remote: desktop-1-ssd → fugui@desktop-1:~/annex/        (热文件)
└── remote: desktop-1-hdd → fugui@desktop-1:/data/cold/annex/  (冷文件)

git annex sync     # 同步位置元数据 (whereis)
git annex get <file>  # 从有内容的 remote 拉取 (SSD 或 HDD)
git annex drop <file> # 用完释放 laptop-1 空间
```

laptop-1 是 `group=manual`(用户控制 get/drop),不自动保留内容。

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

## 跨机工作流

```
laptop-1:  git pull → 工作 → git push
desktop-1: git pull (或直接编辑) → git push
冲突:      git merge (markdown 文本合并好)
审查:      git diff 强制人类审查 agent 修改
```

## 唯一来源验证

desktop-1 在所有数据类型上都是唯一来源:
- 代码: git 仓库本地副本 + push 源 (GitHub 是远程备份)
- 知识库: ~/knowledge/ 主副本 + qmd daemon 主实例
- 密码: passage store 主副本 (git 同步)
- 大媒体: git-annex 主仓库 (SSD + HDD, desktop-1 是唯一完整节点)
- AI 配置: nixos-config flake 主副本
