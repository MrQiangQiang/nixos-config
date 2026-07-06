# 媒体播放架构

## 架构

```
┌─ desktop-1 (canonical) ──────────────────────────────┐
│                                                       │
│  alx ──→ /data/annex/music (音频 + .lrc)             │
│                                                       │
│  music-sync → git commit + beet import + mpc update  │
│                                                       │
│  beets → 元数据 DB (不移动文件)                       │
│                                                       │
│  yazi ──音频──→ mpc ──→ mpd ──→ pipewire              │
│   │              ↑ Unix socket                         │
│   └──视频──→ mpv ──→ wayland                          │
│                                                       │
│  rmpc → mpd (外置 .lrc + 内嵌封面)                    │
└───────────────────────────────────────────────────────┘

┌─ laptop-1 (consumer) ────────────────────────────────┐
│  git-annex-sync --no-content (每小时)                 │
│    ├─ .lrc (git, 真实文件)                            │
│    └─ 音频 (annex, 按需 get)                          │
│                                                       │
│  mpd + rmpc + mpdris2 (播放)                          │
└───────────────────────────────────────────────────────┘
```

## 核心决策

### Unix socket 绑定 MPD

MPD 硬编码安全策略: TCP 连接拒绝 `mpc add` 传文件系统路径。yazi opener 需要传绝对路径,因此额外绑定 Unix socket,opener 通过 socket 连接。TCP 监听保留给 rmpc/mpdris2/beets-mpdstats。

### beets 不重组目录

alx 直接下载到 `/data/annex/music`(扁平结构),beets 只更新数据库。若 beets 移动音频文件,`.lrc` 不会跟随(beets importer 只移动音频),导致 rmpc 歌词路径不匹配。`group_albums` 按 tag 分组而非目录,兼容扁平结构。

music-sync 用 `beet import` 而非 `beet update`:`update` 只刷新已有条目,无法导入新文件(alx 下载的新歌不在 DB 中,`update` 会报 "No matching items found")。

laptop-1 的 git-annex 使用 `--no-content` 同步,文件内容修改不传回 canonical,因此 beets 只能在 desktop-1 运行。

### alx 歌词/封面策略

rmpc 只读外置 `.lrc` 文件(MPD 协议限制,不读内嵌歌词 tag),且使用 `EmbeddedFirst` 读内嵌封面。因此 alx 必须生成外置 `.lrc` 并内嵌封面,不生成外置封面文件(避免 n+1 冗余)和内嵌歌词(冗余)。

### .lrc 走 git 而非 annex

`.lrc` 是小文本文件,若走 annex 需要 `git annex get` 才能读取。通过 `.gitattributes` 使其走 git,随 main 分支自动同步,laptop-1 拉取后直接获得真实文件。

### music-sync 手动触发

alx 无下载完成 hook(源码验证:只有固定的 `beet_import`,不可配置自定义命令)。用户下载后手动执行 `music-sync` 触发同步。

### rmpc 而非 ncmpcpp

foot 终端原生支持 kitty graphics protocol,rmpc 利用此协议内联渲染专辑封面。ncmpcpp 基于 ncurses 纯文本框架,无图片支持。rmpc 歌词显示自己读外置 `.lrc`(源码验证),不需要 rmpcd 守护进程。

### yazi 音频→mpd 队列

人类直觉:选中歌曲 = 立即播放。`mpc clear + add + play` 替换队列并播放,等同所有音乐软件标准行为。视频无队列语义,直接用 mpv 打开窗口。

### mpd 配置变更自动重启

mpd 服务使用 `X-Restart-Triggers` 监听 config hash(参照 `wob.nix` 模式),rebuild 后 systemd 检测变更自动重启。
