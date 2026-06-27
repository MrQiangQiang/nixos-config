# Rose Pine 全局主题架构

> 设计原则：`palette.nix` 唯一来源，darkman 管切换，各应用管自己。不发明第三档，新增应用 = 加 nix + import + darkman 条目。

## 调色板模型

```
dark  → dark_variant（main 或 moon，编译时配置于 osConfig）
light → dawn（固定）
```

## 两层架构

```
palette.nix（唯一来源：三套色值）
    │
    ▼ 编译时：Nix 生成 dark + light 两套配置 → theme/
    │  foot/mako/fuzzel/kwm/gtk/firefox/obsidian/yazi/bat/fcitx5/...
    │
    ▼ 运行时：darkman 触发切换
    │  ln -sf theme/xxx → 实际配置路径 + signal/reload 各应用
```

### 为什么 theme/ 目录 + darkman ln -sf

| 方案 | 问题 |
|------|------|
| HM 直接部署到实际路径 | Nix store 只读，darkman 无法覆盖 |
| darkman cp | hm switch 后需手动 toggle 才生效 |
| darkman ln -sf | ✅ hm switch 自动生效，实际配置 symlink 自动解析到新 store 路径 |

### 为什么 darkman 不集中生成配置

各组件分布式生成自己的主题配置，darkman 只管 `ln -sf` + signal。改 mako 字体只需改 mako.nix，不用同时改 darkman.nix。职责单一。

## 分层传播

| 层 | 传播方式 | 应用 |
|----|----------|------|
| 编译时 | Nix replaceVars → theme/ + darkman ln -sf + signal | kwm/mako/fuzzel/wob/foot/fcitx5/GTK |
| 终端色 | ANSI 16 色自动跟随（无需 darkman） | starship（palette.ansi 语义→ANSI）、fish（Auto theme + OSC 11） |
| 新进程 | OSC 11 启动时检测（无需 darkman） | bat（每次调用是新进程，天然动态切换） |
| Portal | XDG color-scheme（darkman → gsettings → Portal） | Firefox（CSS `light-dark()`）、Spotify、GTK |
| bootstrap | 监听 darkman mode.txt（Portal 对 Electron 不可靠） | Obsidian、Trae CN |

### 为什么 starship 用 palette.ansi 语义映射

`palette.ansi` 将语义名（`s.pine`）映射为 ANSI 名（`blue`），foot 终端解析为正确色值。hex 直写需 darkman 切换两个 toml，语义映射零 darkman 条目、TTY 兼容、Nix 源码自解释。

### 为什么 fish/bat/yazi 不需要 darkman 条目

- **fish**: Auto theme [dark]/[light] + OSC 11 自动跟随终端背景色
- **bat**: 新进程每次调用检测 OSC 11，darkman toggle 后下一次自动正确
- **yazi**: 启动时 OSC 11 检测（持久 TUI，运行中不切换；文件管理器为短会话，可接受）
- **firefox**: CSS `light-dark()` + XDG Portal 自动跟随，无需额外条目

## TTY 主题架构

四层时序确保 TTY 在无 Wayland 环境下正确显示：

| 阶段 | 机制 | 说明 |
|------|------|------|
| Boot | `console.colors` | 固定 dark palette |
| Login | bash `profileExtra` | `mkTtyEscapes` + `clear`，exec fish 前已应用 |
| River Exit | `restore_tty_palette` | kwm 退出后 DRM 重置硬件 LUT，重新应用（补充层） |
| Runtime | fish `tty_theme_sync` | 检测 mode 变化，printf palette + `clear`（主层） |

### 为什么需要 clear

fbcon 将字符渲染为像素，调色板变化后旧像素不变——新旧色混乱。`clear` 触发全屏重绘。

### 为什么 Login 层在 bash 而非 fish

TTY 调色板是 VT 硬件属性，应在 login shell（bash）设置。`exec fish` 前已应用，换交互式 shell 不影响。Runtime 层在 fish 中处理变化检测。

### 为什么 TTY ANSI 映射对齐 foot 而非官方 linux-tty

官方 foot 与 linux-tty 的 ANSI 映射不一致。starship 用 `fg:blue` 表示 pine，若 TTY 跟随官方映射则解析为 foam。对齐 foot 确保跨终端颜色一致。

## KWM 颜色语义

| 角色 | 调色板 | 语义 |
|------|--------|------|
| 选中/活跃 | Rose | 搜索匹配、状态强调，暖色调与冷色调 Text 形成色相差异 |
| 聚焦边框 | Rose | 与 bar 选中统一视觉语言 |
| 非活跃边框 | Highlight High | 弱化但仍可见的边界 |
| 吞噬状态 | Foam | 信息/提示语义 |

### 为什么不透明（ff 而非 d0）

透明度在深色主题几乎无视觉差异，在 Dawn 上降低对比度产生色差。Rose Pine 官方主题不使用透明度。

## fcitx5 集成

### 为什么 fcitx5 主题在系统层（im.nix）而非用户层

用户级 `xdg.configFile` 生成只读 symlink 目录，fcitx5 的 `safeSave()` 写入临时文件失败。系统级 `i18n.inputMethod.fcitx5.settings.addons` 写入 `/etc/xdg/`，fcitx5 通过 `StandardPaths::PkgConfig` 可靠读取。

im.nix 决定"用哪个主题名"，fcitx5.nix 决定"主题长什么样"——两者通过主题名作为合约连接。这是 NixOS 模块系统的自然边界。

### 为什么用 UseDarkTheme 而非 darkman 管理 fcitx5

fcitx5 原生支持 `UseDarkTheme=True`，监听 XDG Portal `color-scheme`（darkman 已通过 gsettings 设置），自动在 Theme/DarkTheme 间切换。无需 darkman 条目。

## Firefox 集成

### 为什么用 CSS 变量 + light-dark() 而非 WebExtension Theme API

NixOS Firefox 编译时 `MOZ_REQUIRE_SIGNING=true`，所有未签名扩展被拒绝。`lockPref` 无效——签名要求是编译时常量。CSS 不需要签名，`light-dark()` 原生跟随系统切换。

### 为什么需要 Dark Reader

`userChrome.css`/`userContent.css` 受安全限制，无法修改外部网页。Dark Reader 是 AMO 签名扩展，automation=system 自动跟随 Portal。

### Variable-First 架构

覆盖 Firefox CSS 自定义属性（design tokens），让 Firefox 内部 CSS 自动消费。变量覆盖 = 面向未来（内部重构不影响主题）、唯一来源（每色定义一次）。

## 诚实边界

| 应用 | 自动化 | 说明 |
|------|--------|------|
| foot/fish/starship | ✅ 完全 | 终端色传播，已运行 shell 即时生效 |
| kwm/mako/fuzzel/wob/GTK | ✅ 完全 | darkman ln -sf + signal/reload |
| bat | ✅ 完全 | 每次新进程检测 OSC 11 |
| Firefox | ✅ 完全 | CSS light-dark() + Dark Reader |
| yazi | ⚠️ 启动时 | OSC 11 启动检测；运行中不切换 |
| Qt 应用 | ⚠️ 近似 | `platformTheme = gtk` |
| Obsidian/Trae CN | ✅ 完全 | bootstrap.cjs 监听 darkman mode.txt |

## 跨文档引用

- 调色板色值定义：`rose-pine-palette.md`
- Firefox CSS 变量映射：`firefox-theme-reference.md`
- KWM SIGUSR1 patch + River 启动时序：`kwm-desktop-plan.md`
- River CSD 边框处理：`river-server-side-decoration.md`
