# River + KWM 极简桌面环境

> River 0.4.5 + KWM 0.3.0 · 非单体架构 · 职责分离

---

## 设计原则

1. **唯一来源**：每个守护进程只有一个启动来源，不重复
2. **职责单一**：river/init 管会话启动，kwm-config.zon 管窗口管理，HM systemd 管有模块的服务
3. **简单优雅**：KWM 内置能力优先（bar/background/FIFO），减少外部组件
4. **面向未来**：新增组件 = 创建 nix + 加 import + 确定启动方式
5. **像拼图**：模块独立，通过 osConfig.custom.desktop 和 palette 连接

---

## 核心架构

```
River 0.4.5 (合成器) ←river-window-management-v1→ KWM 0.3.0 (窗口管理器)
├── KWM 内置 bar (dwm-like 状态栏，FIFO 驱动 status)
├── KWM 内置 background (纯色，-Dbackground=true)
├── KWM 自动 spawn kwim (-Dkwim=true，seat capabilities 事件触发)
│
├── river/init (会话启动脚本，.text 生成)
│   ├── 环境变量 + systemd/dbus 导入
│   ├── graphical-session.target 启动
│   ├── darkman 初始化主题
│   ├── fcitx5 启动
│   ├── kwm（阻塞式，退出后执行 restore_tty_palette）
│   └── restore_tty_palette（TTY 调色板恢复，详见 rose-pine-theme.md）
│
├── kwm startup_cmds (KWM 启动时自动 spawn)
│   └── wl-paste --watch cliphist store / polkit-gnome-authentication-agent-1
│
├── HM systemd services (绑定 graphical-session.target)
│   └── mako / swayidle / kanshi / wob / wlsunset / darkman / kwm-status
│
└── 按需调用 (kwm 键绑定: spawn / spawn_shell)
    └── fuzzel / waylock / grim+slurp / volume-* / brightness-*
```

### 为什么 startup_cmds 不为空

KWM 的 `posix.execve`（[posix.zig:370-402](file:///home/a/third-party/github/kewuaa/kwm/src/posix.zig#L370-L402)）不是标准 C 库的 `execve`——当 argv[0] 不含 `/` 时会搜索 PATH。所以 `.{ "wl-paste" }` 等短名称命令可以正确找到并执行。

| 命令 | 为什么在 startup_cmds | 为什么不在 HM systemd |
|------|---|---|
| wl-paste --watch cliphist store | 剪贴板历史需要尽早启动，与 KWM 生命周期绑定 | systemd 服务启动有延迟，剪贴板事件可能丢失 |
| polkit-gnome-authentication-agent-1 | polkit wrapper 在 PATH 中，KWM 可直接找到 | 同上 |

startup_cmds 中的命令与 KWM 的生命周期绑定——KWM 退出时它们自动终止。

### 为什么 mako 不在 startup_cmds

KWM 的 `spawn_child`（[context.zig:845](file:///home/a/third-party/github/kewuaa/kwm/src/kwm/context.zig#L845)）使用单次 fork，不调用 `setsid()`，不重置信号掩码。mako 通过 `spawn_child` 启动时，其 layer surface 在 KWM 完成 `setDefault()` 之前创建，导致通知不可见。HM systemd 在 `graphical-session.target` 之后启动 mako，此时 KWM 已完成初始化，layer surface 正常工作。

### 为什么 mako/wob/wlsunset/darkman 用 HM systemd

| 服务 | 为什么用 HM systemd | 为什么不在 startup_cmds |
|---|---|---|
| mako | 需要在 KWM 初始化后启动（layer surface 依赖 `setDefault()`）；darkman 需要 `makoctl reload` | spawn_child 时序问题导致 layer surface 不可见 |
| wob | 需要 FIFO socket（`$XDG_RUNTIME_DIR/wob.sock`） | kwm startup_cmds 无法创建 FIFO，wob 需要从 stdin/FIFO 读数据 |
| wlsunset | HM 模块直接生成 systemd 服务 | 不需要 KWM 管理 |
| darkman | HM 模块生成 systemd 服务 + 脚本目录 | darkman 是独立守护进程，不依赖 KWM |
| swayidle | HM 模块直接生成 systemd 服务 | swayidle 监听 idle 事件，不依赖 KWM |
| kanshi | HM 模块直接生成 systemd 服务 | kanshi 监听输出变化，不依赖 KWM |

**分界线**：需要 KWM 完成初始化才能工作的服务、独立守护进程归 HM systemd；与 KWM 生命周期绑定的轻量服务归 startup_cmds。

### 为什么 river/init 用 .text 而 kwm-config.zon 用 .source

| 文件 | 方式 | 原因 |
|------|------|------|
| river/init | `.text` | Shell 脚本，需要 Nix 插值（darkman 路径、schemaDir 等） |
| kwm-config.zon | `.source` → `replaceVars` | 纯 ZON 数据，通过 `@placeholder@` 从 palette.nix 注入色值，零 Nix 路径依赖 |

kwm-config.zon 支持 KWM 预处理器（`@if hostname=...` / `@include`）和热重载（`Mod4+Shift+R` → SIGUSR1），保持为独立文件才能使用这些能力。

### 为什么 overlay 自建 River

nixpkgs 更新滞后，自建时 nixpkgs 中还没有 river 0.4.5。当前 nixpkgs 虽已有 river 0.4.5 官方包，但自建 overlay 保留了控制权（可禁用 xwayland、控制构建选项）。River 上游 0.5.0-dev 正在开发中，overlay 便于跟踪。

---

## KWM spawn 机制

KWM 有两种 spawn 方式，用于不同场景：

| 方式 | 实现 | PATH 搜索 | 用途 | 示例 |
|---|---|---|---|---|
| `spawn` | `posix.execve`（自定义，含 PATH 搜索） | ✅ | 简单命令，纯参数列表 | `.{ .argv = .{ "fuzzel" } }` |
| `spawn_shell` | `spawn(&.{"sh", "-c", cmd})` | ✅（sh 搜索） | 需要 shell 特性（管道/重定向/变量） | 当前未使用（音量/亮度已改用 spawn + 独立脚本） |

KWM 的 `posix.execve`（[posix.zig:370-402](file:///home/a/third-party/github/kewuaa/kwm/src/posix.zig#L370-L402)）不是标准 C 库的 `execve`：当 argv[0] 不含 `/` 时，会遍历 PATH 逐个路径尝试。这是 `execvp` 语义。

startup_cmds 使用 `spawn_child`（[context.zig:845](file:///home/a/third-party/github/kewuaa/kwm/src/kwm/context.zig#L845)），通过 Zig 标准库的 `process.spawn` 启动，同样搜索 PATH。

---

## 启动机制划分

| 启动方式 | 程序 | 原因 |
|---|---|---|
| **kwm startup_cmds** | wl-paste --watch cliphist store, polkit-gnome | 与 KWM 生命周期绑定的轻量服务 |
| **river/init** | fcitx5 | NixOS i18n 模块不自动启动 fcitx5 守护进程 |
| **HM systemd** | mako, swayidle, kanshi, wob, wlsunset, darkman, kwm-status | 独立守护进程或需要 KWM 初始化后启动，绑定 graphical-session.target |
| **kwm 自动** | kwim | `-Dkwim=true` 默认，seat capabilities 事件触发，TTY 切换后自动恢复 |
| **按需调用** | fuzzel, waylock, grim+slurp, volume-*, brightness-* | kwm 键绑定触发 |

---

## 组件清单

| 组件 | 版本 | 来源 | 职责 | 启动方式 | 设计哲学 |
|---|---|---|---|---|---|
| river | 0.4.5 | overlay | Wayland 合成器 | river/init | 非单体架构 |
| kwm | 0.3.0 | overlay | 窗口管理器 + bar + background | river/init → exec kwm | 内置能力优先 |
| kwim | 0.2.0 | overlay | 输入设备管理 | kwm 自动 spawn | 自动恢复 |
| mako | 1.11.0 | nixpkgs | 通知 | HM systemd (手写) | 极简通知 |
| fuzzel | 1.14.1 | nixpkgs | 启动器 | 按需调用 | do one thing well |
| wob | 0.16 | nixpkgs | 音量/亮度 OSD | HM systemd (FIFO) | stdin 接口，极致简单 |
| waylock | 1.6.0 | nixpkgs | 锁屏 | swayidle / 按需 | 极简锁定 |
| swayidle | 1.9 | nixpkgs | 空闲管理 | HM systemd | do one thing well |
| kanshi | 1.8.0 | nixpkgs | 显示器热插拔 | HM systemd | 声明式 profile |
| grim + slurp | 1.5.0 | nixpkgs | 截图 | 按需调用 | 各做一件事 |
| wl-clipboard + cliphist | 2.3.0 / 0.7.0 | nixpkgs | 剪贴板 | startup_cmds (wl-paste --watch) | 各做一件事 |
| wlsunset | — | nixpkgs | 色温 | HM systemd | 原生 Wayland，do one thing well |
| polkit-gnome | — | nixpkgs | 权限认证代理 | startup_cmds (wrapper) | wrapper 在 PATH |
| darkman | 2.3.1 | nixpkgs | 主题切换 | HM systemd | 唯一选择 |
| wpctl | — | nixpkgs (pipewire) | 音量控制 | 按需调用 (spawn volume-*) | WirePlumber 原生，零额外依赖 |
| wlopm | 1.0.0 | nixpkgs | 显示器电源管理 | swayidle 调用 | do one thing well |
| brightnessctl | — | nixpkgs | 亮度控制 | 按需调用 (spawn brightness-*) | 配合 wob OSD |

---

## KWM Bar Status

KWM 内置 bar 的 status 区域通过 FIFO 驱动，由 kwm-status systemd 服务写入。

### 架构

```
palette.nix（唯一来源）
    │ dark/light 语义色
    ▼
kwm-status.nix（mkColors 注入色值到脚本）
    │ writeShellScriptBin → kwm-status
    │ ^#RRGGBBAA 前缀 + ^#! 重置
    │ USR1 信号重载色值（darkman 切换时触发）
    ▼
systemd user service（绑定 graphical-session.target）
    │ [ -p ] 守护 mkfifo + exec 3<> + kwm-status loop
    ▼
$XDG_RUNTIME_DIR/kwm-status.sock（FIFO，inode 跨重启保留）
    │ KWM 以 O_RDWR|O_NONBLOCK 打开（O_RDWR 防止写端断开时 EOF）
    ▼
KWM bar 渲染（fcft 光栅化 + pixman 合成）
```

### 模块

| 模块 | 显示 | 正常色 | 异常色 | 点击 |
|------|------|--------|--------|------|
| 网络 | `NET` / `OFF` | pine | love | 左键→networkmanager_dmenu（fuzzel 菜单，独立模块 networkmanager-dmenu.nix） |
| 代理 | `PX` / `PX!` | foam | love | 无 |
| 电池 | `85%` / `85%+` | foam/gold/love（按电量） | — | 无 |
| 时间 | `Wed 10:30` | subtle | — | 无 |

### 颜色语义

| 语义 | 颜色 | 含义 |
|------|------|------|
| 正常/在线/充足 | pine 或 foam | 一切正常 |
| 注意/中等/充电 | gold | 需要关注 |
| 错误/离线/危险 | love | 需要行动 |
| 日常/低调 | subtle | 不需要行动 |

### 为什么 kwm-status 用 HM systemd 而非 startup_cmds

| 方案 | 问题 |
|------|------|
| startup_cmds | 与 KWM 生命周期绑定，KWM reload 后 FIFO 监听恢复但脚本需重新启动 |
| HM systemd | ✅ 独立于 KWM 生命周期；KWM SIGUSR1 reload 后 `start_listening_status()` 自动恢复 FIFO 监听，脚本无需重启；与 wob 模式一致 |

### 为什么脚本内嵌 dark/light 两套色值而非 darkman 管理配置

| 方案 | 问题 |
|------|------|
| 生成 dark/light 脚本 + darkman 切换 | 需要重启 systemd 服务，增加 darkman 条目 |
| 脚本内嵌两套色值 + USR1 信号切换 | ✅ 一个脚本，一个服务；darkman 只需发 USR1 信号，无需重启 |

### 为什么 status 点击绑定 networkmanager_dmenu

KWM bar status 区域是一个整体，只能绑定左/中/右键三个动作。网络是最需要交互的模块（WiFi 切换），代理/电池/时间不需要点击操作。

| 方案 | 问题 |
|------|------|
| 自定义 wifi-select（fuzzel dmenu + nmcli） | 新网络需密码时静默失败；locale 解析问题；需维护 ~50 行脚本 |
| nmtui connect（foot 终端） | 终端 TUI，与 fuzzel 风格不一致；无 Rose Pine 主题 |
| networkmanager_dmenu + fuzzel | ✅ 复用已有 fuzzel（Rose Pine 主题自动跟随）；Python 成熟工具（242 次提交）；完整功能（密码/VPN/热点/二维码）；零自定义脚本 |

networkmanager_dmenu 的外观完全由 fuzzel 控制——fuzzel 已有 Rose Pine dark/light 配置，darkman 切换时自动跟随。nmdm 的 dark/light INI 配置由独立模块 `networkmanager-dmenu.nix` 生成（与 fuzzel.nix/wob.nix/mako.nix 同模式），darkman 通过 symlink 切换。

---

## 音量/亮度键绑定

音量键和亮度键使用 `spawn` + 独立脚本，通过 wob FIFO 显示 OSD：

### 为什么用 spawn + 独立脚本而非 spawn_shell

| 方案 | 问题 |
|------|------|
| `spawn_shell` + 内联 shell 命令 | 命令字符串嵌入 kwm-config.zon，修改需改 ZON + 重新 replaceVars；shell 命令难以维护和测试 |
| `spawn` + 独立脚本 | ✅ 脚本在 media-keys.nix 中声明式定义，kwm-config.zon 只写 `.{ "volume-up" }` 等短名称；修改脚本无需改 ZON |

### 架构

```
kwm-config.zon (spawn)  →  media-keys.nix (writeShellScriptBin)
  .{ "volume-up" }          volume-up: wpctl set-volume 5%+ + getVolume → wob.sock
  .{ "volume-down" }        volume-down: wpctl set-volume 5%- + getVolume → wob.sock
  .{ "volume-mute" }        volume-mute: wpctl set-mute toggle + getVolume → wob.sock
  .{ "brightness-up" }      brightness-up: brightnessctl set 5%+ + getBrightness → wob.sock
  .{ "brightness-down" }    brightness-down: brightnessctl set 5%- + getBrightness → wob.sock
```

为什么用 wpctl 而非 pactl/pamixer：wpctl 是 WirePlumber 官方 CLI，随 pipewire 自带安装，原生支持 `@DEFAULT_AUDIO_SINK@` 自动跟踪默认设备，零额外依赖。

为什么用 brightnessctl：直接操作 `/sys/class/backlight/`，零额外依赖。

为什么 getVolume/getBrightness 要处理 MUTED 和错误：wob 需要数值输入，静音时显示 "0 muted"，错误时显示默认值 50，避免 wob 无响应。

---

## polkit-gnome Wrapper

[polkit.nix](file:///home/a/nixos-config/home/desktop/polkit.nix) 创建了一个 wrapper 脚本，将 `polkit-gnome-authentication-agent-1` 映射到 Nix store 中的实际路径。KWM 的 `posix.execve` 搜索 PATH 时会找到这个 wrapper：

```nix
home.packages = [
  (pkgs.writeShellScriptBin "polkit-gnome-authentication-agent-1" ''
    exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 "$@"
  '')
];
```

wrapper 模式比在 river/init 中硬编码路径更优雅：kwm startup_cmds 通过 PATH 找到 wrapper，wrapper 内部解析到 Nix store 路径。kwm-config.zon 不需要知道 Nix store 路径。

---

## KWM SIGUSR1 Patch

KWM 不原生支持 SIGUSR1 reload。本地 patch 增强了三处：

1. `src/kwm.zig`：signalfd mask 添加 SIGUSR1
2. `src/kwm/context.zig` handle_signal：USR1 分支调用 `reload_config()` + 无条件 `start_listening_status()` + `bar.damage(.all)` + `manageDirty()`
3. `src/kwm/context.zig` reload_config：修复 `start_listening_status()` 缺失 + 末尾 `manageDirty()`

为什么 SIGUSR1 handler 需要无条件 `start_listening_status()`：`reload_config()` 仅在 `mask.bar == true`（配置变更）时重连 FIFO，但 rebuild 后配置未变时 mask.bar 为 false，FIFO 连接不会恢复。无条件调用确保任何 SIGUSR1 都重建 FIFO 连接（幂等：内部先 stop 再 start）。

为什么需要无条件 damage：`reload_config()` 中 `bar.damage(.all)` 只在 `mask.bar == true` 时调用（配置字段未变则 mask 为 false），但 SIGUSR1 场景下配置文件已被外部 symlink 替换，必须无条件重绘。

---

## auto_swallow 临时禁用

状态：`auto_swallow = false`，临时，等待上游修复。

KWM 0.3.0 `context.deinit()` 退出时，`window.destroy()` 调用 `unswallow()`，后者在 safeIterator 迭代中修改被 swallow 兄弟窗口的链表节点。zig-wayland 安全迭代器合约禁止修改非当前元素（`common_core.zig:139-140`），违规导致悬挂指针 → `unwrapNull` panic → SIGABRT。上游 master 在 v0.3.0 后无相关修复。

禁用 swallow 不损失核心窗口管理能力（平铺/标签/浮动/全屏/键绑定）。恢复条件：kwm 发布上游修复后移除此行配置。

---

## River 启动时序

```
river init:
  1. 环境变量 + systemd/dbus 导入
  2. graphical-session.target 启动 → HM systemd 服务自动启动
  3. portal 重启
  4. darkman get → 执行对应 darkman 脚本 → ln -sf 主题配置到实际路径
  5. darkman set → 同步守护进程状态
  6. fcitx5 -d --replace & → 输入法
  7. kwm → kwm startup_cmds 自动启动 wl-paste/polkit-gnome
  8. restore_tty_palette → kwm 退出后恢复 TTY 调色板（仅 $TERM=linux 时生效）
```

为什么先执行 darkman 脚本再 darkman set：如果 darkman 模式已经是 light，`darkman set light` 不会重新触发 light 脚本（darkman 认为没有变化），但 KWM 启动时需要读到正确的 config.zon。

为什么 fcitx5 在 river/init 中启动：NixOS 的 `i18n.inputMethod` 模块在 Wayland 上不自动启动 fcitx5 守护进程，需要手动 `fcitx5 -d`。

---

## swayidle 关屏

```
300s → waylock 锁屏
600s → wlopm --off * 关闭显示器
       resume → wlopm --on * 恢复显示器
```

为什么用 wlopm：swaybg 设黑壁纸只是把壁纸变黑，显示器背光仍然开启，功耗与正常使用几乎相同。wlopm 通过 `wlr-output-power-management-v1` 协议真正关闭显示器输出，省电并延长显示器寿命。River（wlroots）没有内置 DPMS 支持，需要 swayidle + wlopm。

**`resumeCommand` 是必须的**：wlopm `--off` 关闭显示器后，swayidle 检测到用户活动（鼠标/键盘）时需要执行 `wlopm --on` 恢复显示。没有 `resumeCommand`，屏幕会一直黑屏。

**wlopm 只关闭显示输出**，不影响其他系统功能：
- CPU/内存/网络正常运行
- SSH 远程连接不会断开
- 音频继续播放
- 不会触发系统休眠（suspend/hibernate）
- 等同于"逻辑关屏"（logical screen blanking），显示器功耗降至 0.5W 以下

---

## 文件结构

```
packages/
  river.nix              ← River 0.4.5 (zig_0_16 + wlroots_0_20)
  river/kde-server-decoration.patch ← CSD 补丁
  kwm.nix                ← KWM 0.3.0 (zig_0_16, -Dbackground=true, SIGUSR1 patch)
  kwm/sigusr1-reload.patch
  kwim.nix               ← kwim 0.2.0 (zig_0_16)
  zig-post-configure.nix ← Zig fetchDeps 缓存注入（共享）
  trae-cn.nix            ← Trae CN (bootstrap + Wayland + 主题)
  trae-cn/bootstrap.cjs

modules/
  desktop.nix            ← custom.desktop: enable/package/dark_variant/lat/lng/schemaDir
                          + polkit + PAM waylock + portal (wlr+gtk+darkman) + dconf
  im.nix                 ← fcitx5 输入法 + kbd-layout-viewer5 图标（系统层）

home/desktop/
  palette.nix            ← 唯一来源：三套色值 + gtk/vscode/bat 映射
  kwm/config.zon         ← KWM 模板：@placeholder@ 占位符（palette 色值）
  kwm.nix                ← replaceVars 生成 dark/light ZON → theme/ + kwm/kwim 包
  kwm-status.nix         ← FIFO status 脚本 + HM systemd + palette 语义色
  networkmanager-dmenu.nix ← WiFi 选择器（fuzzel 后端 + dark/light INI） → theme/
  river.nix              ← river/init 脚本 (.text)：环境+darkman+fcitx5+kwm+TTY调色板恢复
  darkman.nix            ← 运行时切换（唯一切换逻辑）：ln -sf + signal + dconf + darkman desktopEntry + 图标
  mako.nix               ← 生成 dark/light mako 配置 → theme/ + HM systemd (手写，不用 services.mako)
  fuzzel.nix             ← 生成 dark/light fuzzel 配置 → theme/ + icon-theme 引用 gtk.iconTheme.name
  wob.nix                ← 生成 dark/light wob 配置 → theme/ + HM systemd (FIFO) + brightnessctl
  foot.nix               ← 生成 dark/light foot 配置 → theme/
  gtk.nix                ← Select-only: 主题名 + 图标主题(Papirus) + dconf + Qt 跟随
  swayidle.nix           ← waylock-theme wrapper + wlopm 关屏（含 resumeCommand）
  waylock.nix            ← waylock 包安装
  kanshi.nix             ← HM systemd
  screenshot.nix         ← grim + slurp + screenshot-region wrapper
  clipboard.nix          ← wl-clipboard + cliphist
  wlsunset.nix           ← HM systemd（原生 Wayland 色温调节）
  polkit.nix             ← polkit-gnome wrapper 脚本
  media-keys.nix         ← 音量/亮度脚本（写入 wob socket）
  keybinds/              ← 快捷键语义注册表（唯一来源）
  keybind-help.nix       ← 快捷键速查脚本（fuzzel dmenu）
  firefox.nix            ← firefox 包
  filemanager.nix        ← yazi + thunar + yazi 图标
  default.nix            ← imports 列表

home/shell/
  default.nix            ← imports + SSH/Git/Vim/基础包
  starship.nix           ← Starship prompt（ANSI 颜色名，跟随终端 16 色）
  fish.nix               ← Fish 4.3+ Auto theme（[dark]/[light] 自动切换）
  bat.nix                ← bat 语法高亮（replaceVars tmTheme + OSC 11 auto + TTY BAT_THEME 回退）
```

---

## 图标管理原则

### 为什么图标不集中到 gtk.nix

| 方案 | 问题 |
|------|------|
| gtk.nix 集中管理所有图标 | gtk.nix 职责是"桌面工具链主题配置"，不是"图标仓库"；AI 无法推断图标归属哪个应用 |
| 各模块 co-location（谁创建 desktopEntry，谁负责图标） | ✅ 图标与应用同处定义，改应用时图标自然跟随；AI 可推断：desktopEntry 旁必有图标 |

### 为什么图标层级跟随安装层级

| 图标 | 位置 | 层级 | 理由 |
|---|---|---|---|
| darkman.svg | darkman.nix | 用户层 | `xdg.desktopEntries.darkman` 同处定义 |
| yazi.svg | filemanager.nix | 用户层 | `programs.yazi` 同处配置 |
| input-keyboard.svg | im.nix | 系统层 | `fcitx5-configtool`（提供 kbd-layout-viewer5）同处安装 |
| trae.png | trae-cn.nix | 包层 | 包定义同处，图标内嵌在 `$out/share/pixmaps/` |

跨层提供图标违反职责单一：fuzzel.nix（用户层）不应知道 kbd-layout-viewer5 来自 im.nix（系统层）。

### 为什么用 hicolor fallback 而非自定义图标主题

| 方案 | 问题 |
|------|------|
| 自定义图标主题 + Inherits=Papirus | hicolor 是最底层 fallback，反向继承制造循环依赖；多一个主题需维护 index.theme |
| 图标放入 `icons/hicolor/scalable/apps/` | ✅ hicolor 是 freedesktop 标准 fallback，fuzzel 三重循环遍历所有 XDG dirs 合并主题实例，无需额外配置 |

Papirus 将 `input-keyboard` 放在 `devices` 上下文，fuzzel 的 `dir_context_is_allowed` 只允许 `applications`/`apps`/`legacy`，所以需要在 `scalable/apps` 中提供。

### 为什么自定义图标不用 Rose Pine 调色板

| 方案 | 问题 |
|------|------|
| 用 Rose Pine dark 色值（#e0def4 等） | Light 主题下浅色对浅色背景，不可见 |
| 用 Rose Pine dawn 色值 | Dark 主题下深色对深色背景，不可见 |
| 两套图标 + darkman 切换 | 违反简单原则：图标是静态文件，fuzzel 不支持运行时切换图标 |
| **用 Papirus 风格中性色（#4f4f4f + #ffffff）** | ✅ 一套图标，dark/light 都可见，零额外复杂度 |

图标 ≠ 主题。Rose Pine 调色板管的是 UI chrome（背景、文字、边框），不是应用图标。fuzzel 不改色——它用 cairo/PixBuf 原样渲染 SVG/PNG。Papirus 图标也不遵循任何主题调色板，它们用自包含配色（深灰底 + 白/灰前景）确保在任意背景下可见。

---

## 条件守卫

所有 Home Manager 桌面模块统一使用：

```nix
let isDesktopEnabled = osConfig.custom.desktop.enable or false; in
lib.mkIf isDesktopEnabled { ... }
```

系统层模块使用：

```nix
let isDesktopEnabled = config.custom.desktop.enable or false; in
lib.mkIf isDesktopEnabled { ... }
```

---

## KWM 配置合并机制

kwm 配置加载是**合并（merge）**，不是替换。`meta.add_default` 将 `config.def.zon` 的默认值嵌入每个字段的 `default_value_ptr`，用户未提供的字段自动使用默认值。但**仅限 struct 类型递归合并**，slice 类型（`bindings.key`、`startup_cmds`、`window_rules`）是**整体替换**，用户必须完整写出所有需要的项。

---

## 为什么 mako 不用 services.mako

`services.mako` 会创建只读符号链接 `~/.config/mako/config`，与 darkman 的动态 `ln -sf` 冲突。手写 systemd service（`Type=dbus` + `BusName=org.freedesktop.Notifications`）不创建配置文件，darkman 可以自由管理 `~/.config/mako/config`。

---

## River 0.5.0 color-management 协议

River 0.5.0-dev 新增了 `wp_color_manager_v1` 协议支持。这是**色彩空间/HDR/ICC 协议**，不是主题切换协议：

| 特性 | color-management-v1 | darkman |
|---|---|---|
| 关注点 | 色彩空间、HDR、ICC、色域 | 桌面主题（dark/light） |
| 工作层面 | 像素级色彩科学 | 应用级外观偏好 |
| 典型用途 | HDR 视频播放、专业色彩校准 | GTK 主题切换、编辑器配色切换 |
| 能否替代 darkman | 否 | — |

color-management-v1 对当前设置基本无关（Intel 集成显卡 HDR 支持有限，`renderer.features.input_color_transform` 大概率为 false）。如果将来使用 HDR 显示器，River 0.5.0 的支持将允许 HDR 内容正确渲染。

---

## 上游版本跟踪

| 组件 | 本地版本 | 上游最新 | 说明 |
|---|---|---|---|
| River | 0.4.5 | 0.4.5 (2026-05-22) | 最新稳定版，0.5.0-dev 开发中 |
| KWM | 0.3.0 | 0.3.0 (2026-05-27) | 最新稳定版 |
| kwim | 0.2.0 | 0.2.0 (2026-05-18) | 最新稳定版，River 0.4.x 唯一的外部输入管理器 |
| darkman | 2.3.1 | 2.3.1 | nixpkgs 已同步上游 |
