# 媒体播放架构

```
┌─ desktop-1 (canonical) ───────────────────────────────────────────┐
│                                                                   │
│  alx (下载器, 用户层)                                              │
│    ├─ 5 个国内平台 native 源: wy/kw/tx/mg/kg                       │
│    ├─ output_dir = /data/annex/music (扁平结构)                    │
│    ├─ embed_cover = true       (封面内嵌 tag)                      │
│    ├─ embed_lyrics = false     (避免冗余, rmpc 只读外置 .lrc)      │
│    ├─ save_lyrics_file = true  (生成 .lrc, 与音频同目录)           │
│    └─ beet_import = false      (用 music-sync 代替)                │
│       ↓                                                           │
│  /data/annex/music/ (扁平结构)                                    │
│    ├─ 周杰伦 - 七里香.flac    (音频, 走 annex)                     │
│    └─ 周杰伦 - 七里香.lrc     (歌词, 走 git)                       │
│       ↓                                                           │
│  music-sync (一键同步, 用户层)                                     │
│    ├─ git add . && git commit  (.lrc→git, .flac→annex, 自动)      │
│    ├─ beet update               (刷新 beets DB, 不移动文件)        │
│    └─ mpc update                (扫描 mpd tag_cache)              │
│       ↓                                                           │
│  beets (元数据, 用户层)                                            │
│    ├─ import.move=false, copy=false (不重组目录)                   │
│    ├─ group_albums=true (按 tag 分组, 处理扁平结构)                │
│    └─ plugins: lastgenre, autobpm, smartplaylist,                 │
│              replaygain, fromfilename                              │
│                                                                   │
│  git-annex-sync (定时)                                             │
│    ├─ 音频: 走 annex (canonical, laptop-1 按需 get)               │
│    └─ .lrc: 走 git (随 main 分支自动同步)                          │
│                                                                   │
├─ 播放管线 (多主机) ────────────────────────────────────────────────┤
│                                                                   │
│  yazi (文件浏览) ──音频──→ mpc CLI ──→ mpd daemon ──→ pipewire    │
│      │                            ↑ MPRIS         ↑ 媒体键         │
│      │                        mpdris2 bridge                      │
│      │                                                             │
│      └──视频──→ mpv ──→ wayland 窗口 (gpu-next)                   │
│                                                                   │
│  rmpc (TUI 客户端, 多主机)                                         │
│    ├─ lyrics_dir = musicDir (镜像 song_file 路径, 扁平→扁平)      │
│    └─ album_art.order = EmbeddedFirst (读内嵌封面)                │
└───────────────────────────────────────────────────────────────────┘

┌─ laptop-1 (consumer) ─────────────────────────────────────────────┐
│  git-annex-sync.timer --no-content (每小时)                        │
│    ├─ pull .lrc (走 git, 真实文件, 无需 annex get)                │
│    └─ pull annex metadata (音频内容按需 get)                      │
│                                                                   │
│  MPD + rmpc + mpdris2 (播放, 用户层)                               │
│    └─ beets / alx / music-sync: 禁用                               │
└───────────────────────────────────────────────────────────────────┘
```

## 组件职责

| 组件 | 职责 | 配置位置 |
|------|------|---------|
| mpd | 音乐播放守护进程, pipewire 输出 | `home/desktop/media.nix` |
| mpdris2 | MPRIS 桥接, 注册至 playerctl | `home/desktop/media.nix` |
| beets | 音乐元数据管理(标签/风格/BPM), 仅 desktop-1, 不重组目录 | `home/desktop/media.nix` |
| alx | 音乐下载器(国内平台), 仅 desktop-1 | `home/desktop/media.nix` |
| music-sync | 一键同步脚本(git commit + beet update + mpc update) | `home/desktop/media.nix` |
| mpv | 视频播放, Wayland 原生 (gpu-next) | `home/desktop/media.nix` |
| rmpc | mpd TUI 客户端, 内嵌封面 + 外置 .lrc 歌词 | `home/desktop/media.nix` |
| yazi opener | 文件管理器音频→mpd, 视频→mpv | `home/desktop/filemanager.nix` |
| mpc | mpd CLI 控制, AI 可 shell 调用 | `home/desktop/media.nix` |
| yt-dlp | 在线媒体下载/流式播放 | `home/desktop/media.nix` |

## 核心决策

### 1. Unix socket 用于 yazi 集成

MPD 硬编码安全策略: TCP 连接拒绝 `mpc add` 传文件系统路径 (`Access to local files via TCP is not allowed`)。yazi opener 传绝对路径, 绕过限制需要在 mpd.conf 额外绑定 Unix socket 并让 opener 通过 socket 连接。

```
services.mpd.extraConfig:  bind_to_address "${dataDir}/socket"
yazi opener:               export MPD_HOST="${socket}"; mpc add "$@"
```

TCP 监听保持不变 — rmpc, mpdris2, beets-mpdstats 仍通过 TCP 正常工作。

### 2. beets 仅 desktop-1, 且不重组目录

beets 导入时写入 ID3/Vorbis 标签到音频文件内部。laptop-1 的 git-annex 使用 `--no-content` 同步(见 `data-sync.md`),文件内容修改不会传回 canonical 仓库。因此 beets 的 `beet import` 只能在 desktop-1 运行。

`import.move=false, copy=false`: alx 直接下载到 `/data/annex/music`(扁平结构),beets 只更新数据库,不移动文件。这避免了 `.lrc` 路径与重组后音频路径不匹配的问题(beets importer 只移动音频文件,不移动 `.lrc`)。

`group_albums=true`: 按 tag(Album + AlbumArtist)分组而非目录,可正确处理扁平结构。MPD 专辑识别也纯依赖 tag,与目录结构无关。

`fetchart` 插件已移除: alx 已内嵌封面到 tag,rmpc 使用 `EmbeddedFirst` 读取,无需外置 `cover.jpg`(避免 n+1 冗余: n 首歌内嵌 n 张封面 + 1 张外置封面)。

laptop-1 上 `programs.beets.enable = false`,mpd 通过标签数据库(tag_cache)提供只读元数据给 rmpc 浏览。

### 3. alx 下载器(替代 lx-music-desktop)

[agent-lx-music](https://github.com/Xuepoo/agent-lx-music) 是 Rust 原生 CLI 音乐下载器,通过 flake input 集成(`inputs.agent-lx-music`),仅 desktop-1 启用。

5 个国内平台 native 源: `wy`(网易云)、`kw`(酷我)、`tx`(QQ)、`mg`(咪咕)、`kg`(酷狗)。这些源既能搜国内歌曲,也能搜国外歌曲(平台版权而定)。`default_source = "all"` 并行搜索所有平台,`platform_priority` 控制优先级。

**输出结构**: alx 的 `filename_template` 不支持目录结构(源码无 `create_dir_all`,`/` 被转义为 `-`),输出为扁平结构。这与 beets `group_albums` 按 tag 分组的设计兼容。

**歌词/封面策略**:
- `embed_cover = true`: 封面内嵌到 tag(rmpc `EmbeddedFirst`)
- `save_lyrics_file = true`: 生成外置 `.lrc`(rmpc 只读外置 `.lrc`,不读内嵌歌词)
- `embed_lyrics = false`: 避免歌词冗余(rmpc 不用)
- `save_cover_file = false`: 避免外置封面冗余(已内嵌)

**无后备下载器**: alx 找不到即接受无歌。nicotine-plus 手动下载纯音频无封面歌词,补充成本高,放弃。

### 4. 歌词同步: 走 git 而非 annex

`.lrc` 是小文本文件,放在 annex 仓库 `/data/annex/music/` 下与音频同目录。通过 `/data/annex/.gitattributes` 配置:

```
*.lrc annex.largefiles=nothing
```

这使得 `.lrc` 走 git(真实文件),音频走 annex(指针)。`git annex sync --no-content` 只跳过 annexed 内容传输,git 跟踪文件(`.lrc`)仍随 `main` 分支同步。laptop-1 拉取后直接获得 `.lrc` 真实文件,无需 `git annex get`。

### 5. music-sync 手动同步

alx 无下载完成 hook(源码验证:只有固定的 `beet_import`,不可配置自定义命令)。用户下载后手动执行 `music-sync`:

```bash
git add .                    # .lrc→git, .flac→annex(自动)
git commit -m "chore(music): sync ..."
beet update                  # 刷新 beets DB, 不移动文件, 不触发插件
mpc update                   # 扫描 mpd tag_cache
```

`beet update` vs `beet import`: `update` 只刷新数据库,不移动文件,不触发插件;`import` 会移动/复制文件并触发插件。由于 `import.move=false, copy=false`,`import` 也只更新数据库,但 `update` 语义更清晰且不依赖交互式匹配。

### 6. rmpc 而非 ncmpcpp

foot 终端(v1.16+)原生支持 kitty graphics protocol。rmpc 使用此协议内联渲染专辑封面。ncmpcpp 基于 ncurses 纯文本框架,无图片支持。

rmpc 歌词显示: 源码验证 rmpc TUI 自己读外置 `.lrc` 文件(`find_current_lyrics_path`),不需要 rmpcd 守护进程。`lyrics_dir` 镜像 `song_file` 的相对路径(扁平结构 → 扁平结构),因此 `.lrc` 必须与音频同目录。

### 7. yazi: 音频→mpd 队列, 视频→mpv 窗口

人类的 Enter 直觉: 在文件管理器选中歌曲 = "我现在要听这个"。`mpc clear + add + play` 替换当前队列并立即播放,等同所有音乐软件的标准行为。视频无队列语义,直接用 mpv 打开窗口。

```yaml
# yazi.toml
[[open.rules]]
mime = "audio/*" → mpd_play
mime = "video/*" → play (mpv)
```

### 8. mpd 配置变更自动重启

参照 `wob.nix` 的 `X-Restart-Triggers` 模式,mpd 服务监听 config hash 变更,rebuild 后 systemd 检测触发自动重启,无需手动 `systemctl restart`。

## 跨主机

| | desktop-1 | laptop-1 |
|---|---|---|
| mpd music_directory | `/data/annex/music` | `~/annex/music` |
| 音频文件 | always present (required) | 按需 `git annex get` |
| .lrc 歌词文件 | 真实文件 (走 git) | 真实文件 (随 main 分支同步) |
| beets | enabled (DB only, no move) | disabled |
| alx | enabled | disabled |
| music-sync | enabled | disabled |
| mpdris2 | enabled | enabled |
| rmpc | enabled | enabled |

## 配置参考

- alx 源码: <https://github.com/Xuepoo/agent-lx-music>
- rmpc 配置文档: <https://mierak.github.io/rmpc/next/configuration/>
- beets 文档: <https://beets.readthedocs.io/>
- LRCLIB (未使用, alx 内置歌词下载): <https://lrclib.net/>
