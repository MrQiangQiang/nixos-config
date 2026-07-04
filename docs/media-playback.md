# 媒体播放架构

```
yazi (文件浏览) ──音频──→ mpc CLI ──→ mpd daemon ──→ pipewire ──→ 扬声器
    │                            ↑ MPRIS         ↑ 媒体键(media-keys.nix)
    │                        mpdris2 bridge
    │
    └──视频──→ mpv ──→ wayland 窗口 (gpu-next)

desktop-1: beets (元数据管理, canonical source)
laptop-1: 仅播放, beets 禁用
```

## 组件职责

| 组件 | 职责 | 配置位置 |
|------|------|---------|
| mpd | 音乐播放守护进程, pipewire 输出 | `home/desktop/media.nix` |
| mpdris2 | MPRIS 桥接, 注册至 playerctl | `home/desktop/media.nix` |
| beets | 音乐元数据管理(标签/风格/BPM), 仅 desktop-1 | `home/desktop/media.nix` |
| mpv | 视频播放, Wayland 原生 (gpu-next) | `home/desktop/media.nix` |
| rmpc | mpd TUI 客户端, kitty 协议封面(foot 原生) | `home/desktop/media.nix` |
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

### 2. beets 仅 desktop-1

beets 导入时写入 ID3/Vorbis 标签到音频文件内部。laptop-1 的 git-annex 使用 `--no-content` 同步(见 `data-sync.md`)，文件内容修改不会传回 canonical 仓库。因此 beets 的 `beet import` 只能在 desktop-1 运行。

laptop-1 上 `programs.beets.enable = false`，mpd 通过标签数据库(tag_cache)提供只读元数据给 rmpc 浏览。

### 3. rmpc 而非 ncmpcpp

foot 终端(v1.16+)原生支持 kitty graphics protocol。rmpc 使用此协议内联渲染专辑封面。ncmpcpp 基于 ncurses 纯文本框架，无图片支持。

### 4. yazi: 音频→mpd 队列, 视频→mpv 窗口

人类的 Enter 直觉: 在文件管理器选中歌曲 = "我现在要听这个"。`mpc clear + add + play` 替换当前队列并立即播放，等同所有音乐软件的标准行为。视频无队列语义，直接用 mpv 打开窗口。

```yaml
# yazi.toml
[[open.rules]]
mime = "audio/*" → mpd_play
mime = "video/*" → play (mpv)
```

### 5. mpd 配置变更自动重启

参照 `wob.nix` 的 `X-Restart-Triggers` 模式，mpd 服务监听 config hash 变更，rebuild 后 systemd 检测触发自动重启，无需手动 `systemctl restart`。

## 跨主机

| | desktop-1 | laptop-1 |
|---|---|---|
| mpd music_directory | `/data/annex/music` | `~/annex/music` |
| 文件内容 | always present(required) | 按需 `git annex get` |
| beets | enabled | disabled |
| mpdris2 | enabled | enabled |
