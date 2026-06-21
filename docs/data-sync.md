# 跨主机数据同步架构

## 核心架构

```
desktop-1 (唯一来源, 7x24) ─── Tailscale SSH ─── laptop-N (消费者)
    │                                              │
    │  /data/annex/ (git-annex on HDD)              │  ~/annex/ (git clone)
    │  group=backup, required="present"             │  group=manual
    │                                              │
    │  git annex add <file>                         │  git annex sync (元数据)
    │  git annex sync                               │  git annex get <file>  (按需拉取)
    │                                              │  git annex drop <file> (用完释放)
```

## git-annex 职责

git-annex 的唯一职责是**管理文件内容在 desktop-1 和 laptop-N 之间的分布**。desktop-1 `/data/annex/` 是 canonical 仓库（group=backup, required="present"），所有文件内容的唯一存放地。laptop-N 按需 `git annex get`/`drop`。

## laptop 拉取工作流

```
laptop-1 ~/annex/:
  git annex sync                 # 拉取元数据 (whereis, git-annex branch)
  git annex get <file>           # 从 desktop-1 HDD 拉取单个文件内容
  git annex drop <file>          # 用完后释放本地空间
```

laptop-1 是 `group=manual`：用户（或 AI agent）显式控制 get/drop，不自动保留内容。`git annex sync` 在 manual 组下只传输元数据，不触发自动内容传输。

## 数据分类与同步方式

| 数据类型 | 同步方式 | 理由 |
|----------|----------|------|
| 代码 + 项目文档 | git + GitHub | 行业标准 |
| 知识库 (markdown) | git only | 版本历史 + 冲突解决 + 人类审查 agent 修改 |
| 密码库 (passage + age) | git only | age 加密设计上允许密文推 GitHub |
| dotfiles / AI 配置 | git only | 已在 nixos-config 仓库 (home-manager 声明式) |
| 大媒体 (照片/视频/音乐/文档) | git-annex | partial checkout 适合低配 laptop; 可释放空间 |
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

## AI 搜索策略（递进式）

```
AI 搜索大文件
├── Layer 1: 本地文件名搜索 (始终可用, 0 网络)
│   find ~/annex -name "*keyword*"
│   git annex find --in=here            ← 列出内容在本地的文件
│
├── Layer 2: git-annex 元数据查询 (始终可用, 0 网络)
│   git annex whereis <file>            ← 文件在哪个 remote
│   git annex list                      ← 列出所有被跟踪的文件名
│
└── Layer 3: 按需拉取后内容搜索 (需网络)
    git annex get <file>                ← 拉取候选文件
    本地搜索文件内容 (EXIF, 全文)
    git annex drop <file>               ← 用完释放
```

## 唯一来源验证

desktop-1 在所有数据类型上都是唯一来源:
- 代码: git 仓库本地副本 + push 源 (GitHub 是远程备份)
- 知识库: ~/knowledge/ 主副本 + qmd daemon 主实例
- 密码: passage store 主副本 (git 同步)
- 大媒体: /data/annex/ 是唯一 canonical 仓库 (HDD, group=backup, required="present")
- AI 配置: nixos-config flake 主副本

desktop-1 有且仅有一个 git-annex 仓库: `/data/annex/`。所有 laptop 从这一个源 clone 和拉取。

## 源码真理

- `modules/git-annex.nix` — 安装 git-annex (仅 desktop-1)
- `hosts/desktop-1/disk-config.nix` — HDD disk.data (btrfs, /data/annex, nofail)
- `hosts/desktop-1/default.nix` — autoScrub, smartd
- `docs/data-storage.md` — 存储架构 (HDD 定位, numcopies 语义)
- `docs/data-protection.md` — 数据保护
