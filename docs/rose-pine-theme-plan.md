# Rose Pine 全局主题方案

> River + KWM · dark/light 二元切换 + dark_variant 配置项

---

## 设计原则

1. **唯一来源**：`palette.nix` 是所有颜色值的唯一定义点
2. **职责单一**：palette 管色值，darkman 管切换，各应用管自己
3. **简单优雅**：不发明第三档，不自定义定时器，脚本无声执行
4. **面向未来**：新增应用 = 创建 nix + 加 import + 加 darkman 条目
5. **像拼图**：模块独立，通过 palette（module arg）和 osConfig 连接

---

## 调色板模型

Rose Pine 三变体，运行时映射为 dark/light 二元：

```
dark  → dark_variant（main 或 moon，编译时配置于 osConfig）
light → dawn（固定）
```

| 变体 | 定位 | dark_variant |
|------|------|-------------|
| Rosé Pine | 标准深色 | `main`（默认） |
| Rosé Pine Moon | 更深高对比 | `moon` |
| Rosé Pine Dawn | 浅色 | —（light 固定） |

---

## 核心架构

```
palette.nix（唯一来源）
    │
    ├── palette.dark / palette.dawn / palette.gtk / palette.vscode
    │
    ▼
┌─────────────────────────────────────────────────────┐
│  编译时：Nix 生成 dark + light 两套配置到 theme/ 目录  │
│                                                       │
│  foot.nix      → theme/foot-{dark,light}.ini         │
│  kwm.nix       → theme/kwm-config-{dark,light}.zon   │
│  mako.nix      → theme/mako-config-{dark,light}      │
│  fuzzel.nix    → theme/fuzzel-config-{dark,light}.ini │
│  wob.nix       → theme/wob-config-{dark,light}.ini   │
│  fcitx5.nix    → theme/fcitx5-{dark,light}/ (theme.conf only, no PNG) │
│  gtk.nix       → Select-only: rose-pine-gtk-theme + Papirus 图标主题 + gtk-im-module  │
│  firefox.nix   → Custom: userChrome.css + userContent.css + Dark Reader              │
│  swayidle.nix  → waylock-theme wrapper（运行时读模式） │
│  starship.nix  → palette.ansi 语义→ANSI 映射 + Powerline + Nerd Font 图标（第零层，自动跟随 foot 16 色）│
│  fish.nix      → Fish 4.3+ Auto theme（palette 注入，[dark]/[light] 自动切换）       │
│  bat.nix       → replaceVars tmTheme 模板 + OSC 11 每次调用检测（CLI 新进程，天然动态切换）  │
│  yazi.nix      → replaceVars flavor.toml + tmtheme.xml 模板 + OSC 11 启动检测（持久 TUI）   │
│  TTY           → console.colors (boot) + mkTtyEscapes (bash login) + river exit restore + fish runtime sync   │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│  运行时：Darkman 触发 dark/light 切换                 │
│                                                       │
│  darkman.nix applyTheme（唯一切换逻辑）:             │
│    1. mkdir -p + ln -sf theme/xxx → 实际配置路径      │
│    2. signal/reload 各应用                             │
│    3. dconf write GTK 主题名 + color-scheme           │
│                                                       │
│  foot 终端 16 色切换 → starship 自动跟随；Fish Auto theme + OSC 11 自动重评估  │
│  （已运行的 shell 即时生效，不需要 darkman 条目）      │
│                                                       │
│  TTY 切换（四层，详见下方 TTY 主题架构）：           │
│    Boot → Login(bash) → River Exit → Runtime(fish)  │
│    fbcon 存像素非索引，palette 变更后必须 clear      │
│                                                       │
│  river.nix init:                                      │
│    1. darkman get → 直接执行对应 darkman 脚本          │
│    2. darkman set → 同步 darkman 守护进程状态          │
└─────────────────────────────────────────────────────┘
```

### 为什么 theme/ 目录 + ln -sf

| 方案 | 问题 |
|------|------|
| HM 直接部署到实际路径 | 符号链接指向只读 Nix store，darkman 无法覆盖文件内容 |
| HM 部署到 theme/ + darkman cp | ⚠️ 配置修改后需 darkman toggle 才能生效（cp 副本不随 HM 更新） |
| HM 部署到 theme/ + darkman ln -sf | ✅ symlink 指向 HM 管理的 theme/ 文件，hm switch 后自动更新 |

为什么 ln -sf 优于 cp：darkman 用 `ln -sf` 创建 symlink 指向 `~/.config/theme/` 下的 HM 管理文件。当 `home-manager switch` 更新 theme/ 下的 symlink（指向新 /nix/store），实际配置路径的 symlink 自动解析到新内容。只需 kwm reload（SIGUSR1）即可生效，无需 darkman toggle。

为什么不存在 HM 与 darkman 的竞争：Home Manager 只管理 `~/.config/theme/` 下的模板文件，不管理 `~/.config/kwm/config.zon` 等实际配置路径。darkman 是实际配置路径的唯一写入者。

为什么 kwm 能读取 symlink：kwm 的 `preprocess.zig` 用 `openFile` 读取配置文件，内核透明解析 symlink。`realPathFileAlloc` 解析 symlink 得到 /nix/store 真实路径，但只用于 `@include` 的基准目录（我们不使用 @include）。

### 为什么 darkman 不生成配置

| 方案 | 问题 |
|------|------|
| darkman.nix 集中生成所有配置 | 违反职责单一：改 mako 字体需同时改两个文件 |
| 各组件分布式生成 + darkman 只做 ln -sf | ✅ 各组件管自己的配置，darkman 只管切换 |

---

## 分层传播

| 层 | 传播方式 | 覆盖应用 | 切换方式 |
|----|----------|----------|----------|
| **第零层** | 终端颜色传播（无需 darkman 条目） | fish / starship | Fish: Auto theme [dark]/[light] + OSC 11；Starship: palette.ansi 语义→ANSI 映射，跟随 foot 16 色 |
| **第零层 B** | replaceVars 模板 + OSC 11 检测 | bat | Bat: tmTheme 模板 + theme-dark/theme-light。每次调用是新进程，天然支持动态切换——darkman toggle 后下一次 `bat` 自动正确 |
| **第零层 B** | replaceVars 模板 + OSC 11 启动检测 | yazi | Yazi: flavor.toml + tmtheme.xml 模板 + [flavor] dark/light。持久 TUI 进程，启动时检测一次，运行中实例不切换（hex 颜色不跟随终端调色板） |
| 第一层 | Nix 生成配置 + ln -sf + signal/reload | kwm/mako/fuzzel/wob/foot/fcitx5 | Darkman 脚本 |
| 第二层 | GTK 主题名（Select-only） | GTK3/GTK4 应用 | dconf write |
| 第三层 | XDG Portal color-scheme | Firefox/Spotify/Electron（纯 Portal） | dconf write → Portal 广播 |
| 第三层 B | bootstrap.cjs 注入（darkman → nativeTheme） | Obsidian / Trae CN | darkman mode 文件监听 → nativeTheme.themeSource |
| 第四层 | Firefox userChrome.css + userContent.css | Firefox Chrome + about: 页面 | Portal prefers-color-scheme → @media 自动切换 |
| 第五层 | Dark Reader (AMO 签名扩展) | Firefox 外部网页 | Portal prefers-color-scheme → automation=system |

Select-only（有原生主题的应用只选主题名）vs Render-own（无原生主题的应用用调色板填色值）vs Custom（无原生主题但可通过扩展 API 精确控制的应用）。

---

## KWM 颜色映射

所有颜色严格遵循 `rose-pine-palette.md` 调色板语义，透明度均为 `ff`（不透明，消除色差）：

| 配置项 | 调色板角色 | 语义 |
|--------|-----------|------|
| `.background` | Base | 一级背景 |
| `.bar.scheme.normal.fg` | Text | 高对比度前景 |
| `.bar.scheme.normal.bg` | Surface | 二级背景 = 状态栏 |
| `.bar.scheme.select.fg` | Rose | 选中/活跃状态 |
| `.bar.scheme.select.bg` | Highlight Med | 选区背景 |
| `.override_colors[].normal.fg` | Text | mode 覆盖前景 |
| `.override_colors[].normal.bg` | Highlight Med | mode 覆盖背景 |
| `.border.color.focus` | Rose | 活跃窗口边框 |
| `.border.color.unfocus` | Highlight High | 非活跃边框 |
| `.border.color.swallowing` | Foam | 吞噬状态 = 信息 |

### 为什么选中/聚焦用 Rose 而非 Pine

Rose 语义 = 搜索匹配/选中状态/活跃强调。选中状态需要双重对比（前景+背景都变），Rose 的暖色调与 Text 的冷色调形成色相差异，视觉区分度优于 Pine 的冷色调。聚焦窗口边框与 bar 选中文字统一视觉语言：活跃 = Rose。

### 为什么不透明（ff 而非 d0）

透明度在深色主题几乎无视觉效果，在 Dawn 上降低对比度产生色差。Rose Pine 官方 VS Code 主题不使用透明度。不透明 = 精确匹配调色板色值。

---

## 各应用颜色映射

| 应用 | 背景 | 前景 | 强调 | 模式 |
|------|------|------|------|------|
| KWM bar | Surface | Text / Rose | Highlight Med | Render-own |
| KWM bar status | — | Pine/Foam/Gold/Love/Subtle（按状态） | — | Render-own |
| networkmanager-dmenu | Base | Text | — | Render-own（obscure_color 跟随 Base） |
| KWM border | — | — | Rose/Highlight High/Foam | Render-own |
| Mako | Overlay | Text | Highlight High | Render-own |
| Fuzzel | Base | Text | Rose/Highlight Med | Render-own |
| Wob | Base | Pine | Highlight High | Render-own |
| Foot | Base | Text | 16色严格映射 | Render-own |
| Waylock | Base | Pine/Love | — | Render-own |
| fcitx5 | Overlay | Subtle/Text | Highlight Med | Render-own |
| GTK | — | — | rose-pine-gtk-theme + Papirus 图标主题 + gtk-im-module | Select-only |
| Firefox | Base/Surface/Overlay | Text | Rose/Highlight Med | Custom |
| Yazi | Base/Surface | Text | Pine/Foam/Rose/Love/Gold/Iris | Render-own (replaceVars) |
| Bat | Base/Surface | Text | Pine/Foam/Rose/Gold/Iris/Love | Render-own (replaceVars) |

### Yazi 架构决策

**数据流**：`palette.nix` → `mkFlavorVars`(14色) → `replaceVars flavor.toml` → `flavors/{name}.yazi/flavor.toml`；`palette.nix` → `mkTmThemeVars`(13色 + extra) → `replaceVars tmtheme.xml` → `flavors/{name}.yazi/tmtheme.xml`。

**为什么 `[mgr]` 不是 `[manager]`**：yazi-config 源码中结构体 `Mgr` 对应 TOML section `[mgr]`。home-manager yazi 模块直接将 Nix attrset 映射为 TOML section，所以 `settings.mgr` 生成 `[mgr]`，`settings.manager` 会生成不存在的 `[manager]` section 导致所有设置被忽略。

**为什么 `syntect_theme = ""`**：yazi 源码 `flavor.rs` 中，当 `syntect_theme` 为空字符串时，`syntect_path()` 自动查找同目录下的 `tmtheme.xml`。这是 yazi 官方 flavor 的标准做法——flavor.toml 和 tmtheme.xml 同目录，无需硬编码绝对路径。

**为什么 `mkTmThemeVars` 用 `c: extra:` 模式**：tmtheme.xml 的 16 个占位符中，13 个是调色板颜色（来自 palette），3 个是变体元数据（`name`/`semantic_class`/`uuid`）。元数据不是调色板的一部分，不应加入 palette.nix（违反职责单一）。`extra` 参数将元数据与颜色分离，在 filemanager.nix 调用点按变体传入。

**为什么 `initLua` 注册 `Linemode:size_and_mtime()`**：yazi 内置 linemode 只支持 `none`/`size`/`mtime`/`permissions`/`owner` 单一显示。自定义 linemode 通过 `init.lua` 在 `Linemode` 表上添加方法，`solo()` 运行时通过 `self[mode]` 动态查找。加载时序：stage_1 加载 `linemode.lua`（定义 `Linemode` 表），stage_2 加载 `init.lua`（扩展 `Linemode` 表），运行时 `solo()` 可正确找到自定义方法。

| Trae CN | — | — | Rosé Pine 扩展 | Select-only |
| Obsidian | Base/Surface/Overlay | Text | Rose/Highlight Med | Custom（官方主题 + replaceVars snippet） |

Mako 背景 = Overlay（三级背景 = 浮层/弹窗/通知）。Fuzzel 背景 = Base（全屏启动器用主背景）。fcitx5 背景 = Overlay（浮层 = 输入法候选框）。

### fcitx5 集成

fcitx5 主题是目录结构（`theme.conf`），放在 `~/.local/share/fcitx5/themes/{name}/`。

**为什么不需要 radio.png/arrow.png**：这两个 PNG 仅用于 XCBMenu（系统托盘右键菜单）。我们的 Wayland + KWM 环境没有系统托盘，XCBMenu 永远不会被触发（`waylandui.cpp` 中零 menu 代码）。即使被触发，fcitx5 也会回退到纯色矩形（`theme.cpp:327`）。

**为什么 classicui.conf 在 im.nix（系统层）而非 fcitx5.nix（用户层）**：用户级 `xdg.configFile` 使用 linkFarm（只读 nix store symlink 目录），fcitx5 的 `safeSave()` 写入时因目标目录只读而失败（write-and-rename 模式无法在只读目录创建临时文件）。系统级 `i18n.inputMethod.fcitx5.settings.addons` 写入 `/etc/xdg/fcitx5/conf/classicui.conf`，fcitx5 通过 `StandardPaths::PkgConfig` 搜索可靠读取（User > System 优先级）。两者通过主题目录名（`rose-pine-dark`/`rose-pine-light`）作为合约连接——im.nix 决定"用哪个主题"，fcitx5.nix 决定"主题长什么样"。这是 NixOS 模块系统的自然边界：`i18n.inputMethod` 是系统级选项，`palette` 是 home-manager 参数，无法合并。

**为什么用 UseDarkTheme 而非 darkman 管理 fcitx5**：fcitx5 原生支持 `UseDarkTheme=True`，监听 XDG Portal `color-scheme` 属性（darkman 已通过 gsettings 设置），自动在 `Theme`（light）和 `DarkTheme`（dark）之间切换。无需 darkman 条目、无需 `fcitx5 -r`、无需 symlink 交换。

**为什么两个固定目录（rose-pine-dark/rose-pine-light）而非一个 symlinked current**：UseDarkTheme 机制要求 Theme 和 DarkTheme 指向不同的固定目录名。

**为什么用 `pkgs.runCommand` derivation 而非 `home.file` 逐文件**：

| 方案 | 问题 |
|------|------|
| `home.file` 逐文件 | 每个文件是独立的 nix store symlink；darkman `ln -sf` 目录到此路径会创建自引用 symlink |
| `pkgs.runCommand` 单 derivation | ✅ 一个 derivation → 一个目录路径 → home-manager 创建单个目录级 symlink；所有文件是真实文件（非 symlink） |

**为什么 profile 在 fcitx5.nix 中声明式管理**：`i18n.inputMethod` 模块只安装 addon，不配置 IM group。声明 profile（keyboard-us + pinyin）确保 Ctrl+Space 开箱即用。

### Yazi / Bat 集成（replaceVars + OSC 11）

Yazi 和 bat 共享同一构建时架构：palette.nix → replaceVars 模板 → 应用主题系统 + OSC 11 检测。但**运行时行为不同**：

- **bat**：CLI 工具，每次调用是新进程。`terminal_colorsaurus::theme_mode()` 每次检测终端 OSC 11 → 选择 `theme-dark` 或 `theme-light`。天然支持动态切换——darkman toggle 后下一次 `bat` 自动正确。TTY fallback 通过 fish `bat_tty_theme` 函数设置 `BAT_THEME` 环境变量。
- **yazi**：持久 TUI 进程。`EMULATOR.light` 是 `RoCell`（启动时一次性写入），`app:theme` 不重新检测终端 dark/light。运行中实例不切换——darkman toggle 后需退出重启。

**为什么用 replaceVars 模板而非官方主题**：palette.nix 是唯一来源。dark_variant（main/moon）是编译时配置，官方主题不知道这个配置。切换 dark_variant 需要替换整个主题文件，replaceVars 模板自动处理。

**为什么不用 ANSI 颜色名（第零层）**：ANSI 16 色无法覆盖 15 个语义色需求（muted/subtle/highlight_low/med/high 无对应 ANSI 槽位）。starship 只需 8 个前景色 → 完美匹配 ANSI 8 色；yazi/bat 需要完整调色板 → 必须 hex 直写。

**为什么 yazi 运行中实例不切换**：hex 颜色输出 `\x1b[38;2;R;G;Bm`（真彩色），不跟随终端调色板变化。yazi 的 `EMULATOR.light` 是 `RoCell` 一次性写入，`app:theme` 不重新查询终端。文件管理器是短会话应用，新实例通过 OSC 11 自动正确。

**为什么不需要 darkman 条目**：bat 每次调用自动检测（新进程），yazi 启动时自动检测（短会话应用）。强行添加 darkman 条目需要管理 yazi 实例 ID + `ya emit-to` + 修改 theme.toml，违反简单原则。

**Yazi flavor 结构**：`programs.yazi.flavors` 安装 flavor 目录（flavor.toml + tmtheme.xml），`theme.flavor` 声明 dark/light 选择。yazi 启动时通过 OSC 11 查询终端背景色亮度 → `EMULATOR.light` → `build_flavor(light)` 选择 `flavor.dark` 或 `flavor.light`。

**图标颜色**：已集成到 flavor.toml 模板的 `[icon]` 段（~650 条 Nerd Font 图标颜色映射）。yazi 的 Theme 结构体包含 `icon` 字段，`deserialize_over` 会解析 flavor.toml 中的 `[icon]`，因此图标颜色随 flavor dark/light 自动切换——无需额外 darkman 条目或 theme.toml 配置。

**图标弱化色统一为 `@muted@`**：官方主题对"弱化色"在不同变体用了不同语义色（main 用 highlight_low/highlight_high/overlay，moon/dawn 用 muted/highlight_high/text）。统一为 `muted` 确保：所有背景上可见；匹配 moon/dawn 官方的大多数位置；main 变体中这些图标从"几乎不可见"变为"弱化但可见"（可用性更好）。

### 为什么 Starship 用 palette.ansi 语义映射

| 方案 | 问题 |
|------|------|
| hex 直写（`fg:"#c4a7e7"`） | 需 darkman 切换两个 toml 文件；HM `programs.starship` 与 darkman 竞争写入；TTY hex 近似不可预测 |
| 硬编码 ANSI 名（`fg:blue`） | 不可读：需查映射表才知道 `blue` = pine；AI 维护成本高 |
| palette.ansi 语义映射 | ✅ `s.pine` → `"blue"` → foot 解析为 pine 色；Nix 源码自解释；零 darkman 条目；TTY 兼容 |

`palette.ansi` 是语义→ANSI 名的唯一来源，与 `foot.nix regular0-7` 和 `mkTtyEscapes P0-P7` 对齐。Nix `''` 字符串中 `\(` `\$` `\[` `\]` 是字面字符，`$var`（无花括号）也是字面，`${s.xxx}` 是 Nix 插值 — 零转义心智负担。

### 为什么 Fish 用 Auto theme 而非 ANSI 颜色名

| 方案 | 问题 |
|------|------|
| ANSI 颜色名（black/white 等） | `black` = Overlay（`#26233a`），在 Base 背景上几乎不可见；ANSI 16 色无 Subtle 槽位 |
| Fish 4.3+ Auto theme | ✅ `[dark]`/`[light]` 段落 + hex 色值，精确匹配官方；OSC 11 自动跟随终端背景色切换 |

### TTY 主题架构

TTY（Linux 虚拟控制台）无 Wayland，但 darkmand 通过 `default.target` 在用户登录后自动运行（不受 `graphical-session.target` 限制），因此 `darkman toggle` 在 TTY 中可直接使用。四层机制：

| 阶段 | 机制 | 说明 |
|------|------|------|
| Boot | `console.colors`（desktop.nix） | 固定 dark palette，登录前显示 |
| Login | bash `profileExtra` 读 `mode.txt`（bash.nix） | `mkTtyEscapes` + `clear`，独立于交互式 shell |
| River Exit | `restore_tty_palette`（river.nix） | kwm 退出后 printf palette + clear（补充层） |
| Runtime | `tty_theme_sync`（onEvent fish_prompt） | 检测 mode 变化，printf palette + `clear`（主层） |

### 为什么需要 clear

fbcon（framebuffer console）将字符渲染为像素存入 framebuffer。`\033]Pn` 更新硬件 cmap 但不触发 fbcon 重绘，已有像素不变——旧文本保持旧色，新文本显示新色，视觉混乱。`clear` 清空屏幕缓冲区并触发全屏重绘，所有内容以新 cmap 渲染。

VGA 文本模式（vgacon）下色值通过硬件 CLUT 在扫描时解析，调色板变化立即生效——但现代系统均使用 fbcon（DRM/KMS），vgacon 不在使用路径上。

### 为什么需要 River Exit 层（补充层）

River 退出时 `drm_lastclose()` 将硬件 LUT 重置为内核默认值（线性渐变），覆盖用户自定义调色板（i915/amdgpu 均如此）。`restore_tty_palette` 在 kwm 退出后重新应用调色板。

此层是补充层，可能在 KD_GRAPHICS→KD_TEXT 时序中失效。Runtime 层（`tty_theme_sync`）是主层——fish 恢复控制后一定正确重新应用调色板 + clear。

为什么不用 `exec kwm`：shell 进程需要在 kwm 退出后执行 `restore_tty_palette`。`exec` 替换 shell 进程，导致 restore 无法执行。

### 为什么 Login 层放在 bash 而非 fish

| 方案 | 问题 |
|------|------|
| fish `interactiveShellInit` | TTY 调色板是 VT 硬件属性，不是 fish 的职责；换 shell = 丢失 Login 层 |
| bash `profileExtra` | ✅ bash 是 login shell，一定存在；调色板在 `exec fish` 之前就已应用；换交互式 shell 不影响 Login 层 |

Login 层（bash）与 Runtime 层（fish）职责分离：bash 负责"登录后第一次应用正确调色板"，fish 负责"运行时检测变化并同步"。`__tty_theme_mode` 通过环境变量从 bash 传递到 fish，避免重复读取。

### 为什么 TTY ANSI 映射对齐 foot 而非官方 linux-tty

官方 `rose-pine/linux-tty` 和 `rose-pine/foot` 的 ANSI 映射不一致：

| ANSI 槽位 | foot | linux-tty | 冲突 |
|-----------|------|-----------|------|
| black(0) | overlay | base | 背景色不同 |
| green(2) | foam | pine | **互换** |
| blue(4) | pine | foam | **互换** |

starship 使用 `fg:blue` 表示 pine。如果 TTY 跟随官方映射，`fg:blue` 在 TTY 中解析为 foam — 跨终端颜色不一致。对齐 foot 映射后，starship 在 TTY 和图形终端中颜色一致。

### 为什么 Fish `[unknown]` 段用 ANSI 名而非 hex

TTY 不响应 OSC 11，Fish 4.3+ 查找 `[unknown]` 段。两种方案：

| 方案 | 问题 |
|------|------|
| hex 色值 | TTY 只支持 16 色，hex 近似映射不可预测 |
| ANSI 名（magenta/blue/cyan 等） | ✅ 通过 TTY 16 色调色板可靠解析；`mkTtyEscapes` 切换调色板后 ANSI 名自动适配 |

`[unknown]` 段是 mode-agnostic 的——不需要知道当前 dark/light，ANSI 名通过调色板间接解析。

### 为什么图标主题用 Papirus 而非 rose-pine-icons

| 方案 | 问题 |
|------|------|
| rose-pine-icons | `rose-pine-gtk-theme` 的 `share/icons/` 为空，不提供任何图标主题；社区无独立的 rose-pine-icons 包 |
| Papirus | ✅ 社区最流行的 SVG 图标主题之一，覆盖率高，继承 hicolor 作为 fallback |

图标主题唯一来源：gtk.nix 声明 `iconTheme.name = "Papirus"`，fuzzel 通过 `config.gtk.iconTheme.name` 引用。Papirus 不提供的自定义应用图标，通过 hicolor fallback 机制补充（见 kwm-desktop-plan.md "图标管理原则"）。

---

## KWM SIGUSR1 Patch

详见 [kwm-desktop-plan.md](kwm-desktop-plan.md#kwm-sigusr1-patch)。

---

## River 启动时序

详见 [kwm-desktop-plan.md](kwm-desktop-plan.md#river-启动时序)。

---

## Trae CN 集成

`trae-bootstrap.cjs` 替代原始 `main.js` 入口，实现：

1. 启动时读取 `~/.cache/darkman/mode.txt`，设置 `nativeTheme.themeSource` + `workbench.colorTheme`
2. 监听 `mode.txt` 文件变化（`fs.watch` + `fs.watchFile` 双保险），实时同步主题
3. Wayland 检测：有 `WAYLAND_DISPLAY` 时添加 Ozone + IM 参数
4. 主题名通过 `pkgs.replaceVars` 从 palette.nix 编译时注入

---

## Firefox 集成

三层 CSS + Dark Reader 架构，每层职责单一、互不重叠：

| 层 | 覆盖范围 | 工具 | dark/light 切换 |
|----|---------|------|----------------|
| Chrome UI | 标签栏/工具栏/侧边栏/弹窗 | `userChrome.css` | `light-dark()` CSS 函数 |
| about: 页面 | newtab/preferences/addons | `userContent.css` | `light-dark()` CSS 函数 |
| 外部网页 | google.com/github.com 等 | Dark Reader (AMO 签名扩展) | automation=system |

> 详细变量映射见 [firefox-theme-reference.md](firefox-theme-reference.md)

### 为什么不用 WebExtension Theme API

NixOS Firefox 编译时 `MOZ_REQUIRE_SIGNING=true`，所有未签名扩展（包括自建主题 XPI）在安装时被静默拒绝。`lockPref("xpinstall.signatures.required", false)` 无效，因为 `AddonSettings.REQUIRE_SIGNING` 源自编译时常量，不受运行时 pref 控制。

### 为什么用 CSS + `light-dark()` 而非 JS API

CSS 不需要签名，不需要 JavaScript，通过 `light-dark()` 函数原生跟随系统 dark/light 切换。`light-dark()` 在 computed value 阶段求值，对 `RecascadeSubtree` 更鲁棒。

### 为什么需要 Dark Reader

`userChrome.css` 和 `userContent.css` 受浏览器安全限制，无法修改外部网页内容。Dark Reader 是 AMO 签名扩展，内置 Rosé Pine 配色（`background=Base`, `text=Text`），automation=system 自动跟随 `prefers-color-scheme`。Dark Reader 是颜色反转工具，accent 颜色通过 HSL 算法变换，不会精确匹配 Rose Pine——这是固有限制。

**注意**：Dark Reader 的 `changeBrowserTheme` 功能必须保持禁用，否则会与 `userChrome.css` 冲突。

### 为什么不需要 darkman 条目

Firefox 三层主题都通过 `prefers-color-scheme` 自动跟随系统。darkman 已经通过 `gsettings set color-scheme` 触发 XDG Portal 广播，无需新增 darkman 条目。

### Variable-First 架构

覆盖 Firefox 的 CSS 自定义属性（design tokens），让 Firefox 内部 CSS 自动消费变量。变量覆盖 = 面向未来（Firefox 内部重构选择器不影响主题）、低复杂度（一个变量覆盖多个选择器）、唯一来源（每个颜色只定义一次）。

`--rp-*` 变量同时定义在 `:root` 和 popup 边界元素上（`panel`, `menupopup`, `tooltip`, `#tab-preview-panel`, `#tab-note-preview-panel`），确保分离 DOM 子树也能正确继承。

### Defense in Depth（双写策略）

Variable-First 覆盖 `:root` 变量，但三类场景需要直接选择器覆盖：

| 场景 | 原因 | 示例 |
|------|------|------|
| 分离 DOM 子树 | `panel`/`panelview`/`menupopup` 不继承 `:root` 变量 | `panelview { background-color }` |
| CSS 系统颜色 | `Field`/`FieldText` 由 `color-scheme` 决定，不消费 CSS 变量 | `--input-text-background-color: Field` |
| 平台原生外观 | `-moz-appearance: tooltip` 委托 GTK 渲染，忽略 CSS 属性 | `tooltip { -moz-default-appearance: none }` |

### Firefox 151 变量体系

Firefox 150+ 已完全迁移到新 Design Token 系统，`--in-content-*` 变量已从源码中移除。userContent.css 仅需覆盖新设计令牌（`tokens-brand.css` / `tokens-shared.css`）+ `--input-text-*` + `--newtab-*` + `--fxview-*` + `--toggle-*`。

搜索框关键问题：`moz-input-search` 消费 `--input-text-*` 变量（默认值 `Field` = CSS 系统颜色，light 模式 = 白色），而非 `--input-bgcolor`（使用 `light-dark()` 函数）。两套变量体系独立，都必须覆盖。

### CSD 边框处理

Firefox 在 Wayland 上默认使用 CSD，与 kwm 的 SSD 冲突。解决链：River 广播 `org_kde_kwin_server_decoration` 协议 → GTK3 `prefers_ssd()` 返回 TRUE → `MOZ_GTK_TITLEBAR_DECORATION=system` → `browser.tabs.inTitlebar=1` → `userChrome.css` 隐藏 CSD 按钮。详见 [river-server-side-decoration.md](river-server-side-decoration.md)。

### 已知限制：运行时切换（Wayland/River）

**NAC Tooltip**：部分按钮的悬停浮层受 `xul.css`（UA Sheet）的 `InfoBackground`/`InfoText` 系统颜色控制，`userChrome.css` 无法匹配。Wayland/River 上缺少 `gnome-settings-daemon` 桥接，`InfoBackground`/`InfoText` 运行时不更新。启动时的正确性由 `gtk-tooltip-*.css` 保障（darkman 切换时 symlink 到 `~/.config/gtk-3.0/gtk.css`）。

**Tab 预览面板**：Shadow DOM 内 `::part(content)` 的 `var()` 在 `RecascadeSubtree` 时不重新求值。

**解决方案**：切换主题后重启 Firefox。重启后所有元素从 GTK/CSS 重新读取正确颜色。host 级元素（标签栏、工具栏、地址栏等）由 `light-dark()` 确保运行时实时切换。

---

## Obsidian 集成

三层 CSS 覆盖 + bootstrap.cjs 注入（同 [Trae CN](#trae-cn-集成) 模式）。

**bootstrap.cjs**：Linux 上 XDG Portal color-scheme 信号不可靠传递到 Electron（确认 v1.12.4，2026 年 3 月）。注入 app.asar：读 darkman mode → `nativeTheme.themeSource` → Obsidian 的 `nativeTheme.on("updated")` 接管。禁用 `PrefersColorSchemePortal`。

**三层 CSS 覆盖**（snippet 通过 replaceVars 从 palette.nix 注入，列出所有变体类匹配官方特异性 0,2,0，snippets 在 theme.css 后加载 → 胜出）：

| 层 | 覆盖 | 为什么 |
|----|------|--------|
| `--rp-*` 调色板 | 15 变量 × dark/light | dark_variant（main/moon）是编译时配置，官方主题分别硬编码 |
| `--rp-accent` / `--rp-highlight` | @settings 默认值 | 官方 CSS fallback：accent=iris（紫），highlight=undefined。@settings 默认值需要 Style Settings 插件，我们未安装 |
| `--accent-h/s/l` / `--text-highlight-bg-rgb` | Obsidian 基础 accent 变量 | 官方只覆盖衍生变量，不覆盖基础变量。Obsidian 默认紫色（h=258），影响标签/焦点环/active-hover 等数十个元素 |

**对比度修复**：官方 `--text-on-accent: var(--rp-accent)`（粉）在 `--background-modifier-error: var(--rp-love)`（也粉）上不可见。6 个受影响元素覆盖 `--text-on-accent: var(--rp-base)`（moon 5.25:1 AA，dawn 4.09:1 AA 大文本）。

**activation script 而非 home.file**：`.obsidian/` 运行时管理（workspace.json/cache 频繁变化），symlinking 会破坏。`cp -f` 部署 + `jq` 合并 appearance.json。

**Starter screen 修复（vault 切换器 + 版本信息弹窗 + Help 界面）**：`starter.html` 和 `help.html` 都硬编码 `<body class="theme-dark">` 且只加载 `app.css`（不加载 vault 级别 theme.css/snippets）。`main.js` 创建这些窗口时背景色硬编码 `#1e1e1e`，无 `insertCSS`/`nativeTheme`/主题类操作。结果：这些窗口永远是 Obsidian 默认 dark 主题，不跟随 Rose Pine 或系统 dark/light。

修复：bootstrap.cjs 监听 `app.on("web-contents-created")`，检测 URL 含 `starter.html` 或 `help.html` 时：(1) `executeJavaScript` 修正 body class 为 darkman mode 对应的 `theme-dark`/`theme-light`；(2) `insertCSS` 注入 `~/.config/obsidian/starter.css`。CSS 覆盖 `--color-base-*` 12 槽 + `--accent-h/s/l` + `--text-on-accent`（覆盖 app.css 硬编码 `white`，改为 `var(--color-base-00)` 确保 dark/light 都有对比度），并修复 `.splash-brand-logo-text { color: white }` 硬编码为 `var(--text-normal)`。`body.starter.theme-dark` 特异性 0,2,1 > app.css `.theme-dark` 0,1,0。CSS 由 home-manager replaceVars 从 palette.nix 生成，部署到全局 `~/.config/obsidian/`（pre-vault，非 vault 级别）。`dom-ready` 事件触发注入（DOM 解析后、绘制前，避免闪烁）。

---

## 文件结构

```
home/desktop/
  palette.nix          ← 唯一来源：三套色值 + gtk/vscode/bat/yazi/tty/ansi 映射
  kwm/config.zon       ← KWM 模板：@placeholder@ 占位符
  firefox/userChrome.css ← Firefox Chrome UI 模板：@placeholder@ 占位符
  firefox/userContent.css ← Firefox about: 页面模板：@placeholder@ 占位符
  firefox/gtk-tooltip-dark.css ← GTK tooltip dark（Firefox NAC tooltip）
  firefox/gtk-tooltip-light.css ← GTK tooltip light
  firefox/dark-reader-settings.json ← Dark Reader 扩展配置
  filemanager/rose-pine-yazi-flavor.toml ← Yazi flavor 模板：@placeholder@ 占位符
  filemanager/rose-pine-yazi-tmtheme.xml ← Yazi 语法高亮模板：@placeholder@ 占位符
  kwm.nix              ← replaceVars 生成 dark/light ZON → theme/
  kwm-status.nix       ← FIFO status 脚本 + HM systemd + palette 语义色
  networkmanager-dmenu.nix ← WiFi 选择器配置（fuzzel 后端） → theme/
  mako.nix             ← 生成 dark/light mako 配置 → theme/
  fuzzel.nix           ← 生成 dark/light fuzzel 配置 → theme/ + icon-theme 引用 gtk.iconTheme.name
  wob.nix              ← 生成 dark/light wob 配置 → theme/
  foot.nix             ← 生成 dark/light foot 配置 → theme/
  fcitx5.nix           ← 生成 dark/light fcitx5 主题 → theme/ (theme.conf only, no PNG)
  gtk.nix              ← Select-only: 主题名 + 图标主题(Papirus) + gtk-im-module + dconf + Qt 跟随
  firefox.nix          ← Custom: replaceVars 生成 userChrome.css + userContent.css + Dark Reader policy
  filemanager.nix      ← Yazi: replaceVars flavor.toml + tmtheme.xml → programs.yazi.flavors + OSC 11
  darkman.nix          ← 运行时切换（唯一切换逻辑）：ln -sf + signal + dconf
  river.nix            ← 启动初始化：执行 darkman 脚本 + darkman set + TTY 调色板恢复
  swayidle.nix         ← waylock-theme wrapper（运行时读模式）
  waylock.nix          ← waylock 包安装
  polkit.nix           ← polkit 认证代理
  screenshot.nix       ← grim + slurp
  default.nix          ← imports 列表

home/shell/
  bash.nix             ← Login shell + TTY Login 层（profileExtra: palette.tty 读 mode.txt）
  starship.nix         ← palette.ansi 语义→ANSI 映射 + Powerline 胶囊 + Nerd Font 图标（第零层，自动跟随 foot 16 色）
  fish.nix             ← Fish 4.3+ Auto theme + TTY Runtime 层（tty_theme_sync）+ [unknown] 段
  bat.nix              ← replaceVars tmTheme 模板 + OSC 11 自动检测 + TTY fallback（同 yazi 模式）
  rose-pine-bat.tmTheme ← Bat tmTheme 模板：@placeholder@ 占位符
  default.nix          ← imports + SSH/Git/Vim/基础包

home/dev/
  obsidian.nix         ← Obsidian：官方主题 + replaceVars snippet 部署 + starter.css 部署 + appearance.json 合并
  rose-pine-obsidian.css ← Obsidian CSS snippet 模板：@placeholder@ 占位符（vault 级别）
  rose-pine-obsidian-starter.css ← Obsidian starter screen CSS 模板：@placeholder@ 占位符（全局，pre-vault）

packages/
  kwm.nix              ← kwm 构建：-Dbackground=true + SIGUSR1 patch
  kwm/sigusr1-reload.patch ← 三处增强（含无条件 start_listening_status 重连）
  river.nix            ← river 构建（overlay，含 CSD 补丁）
  river/kde-server-decoration.patch ← CSD 补丁
  zig-post-configure.nix ← Zig fetchDeps 缓存注入（kwm/river/kwim 共享）
  trae-cn.nix          ← Trae CN 包：bootstrap + Wayland + 主题参数
  trae-cn/bootstrap.cjs ← Darkman 集成 + Wayland 检测
  obsidian.nix          ← Obsidian 包覆盖：bootstrap.cjs 注入 app.asar
  obsidian/bootstrap.cjs ← Darkman → nativeTheme 桥接 + starter screen CSS 注入（同 trae-cn 模式）

modules/desktop.nix    ← dark_variant + latitude/longitude + schemaDir + portal
home/default.nix       ← palette 注入为 _module.args
```

---

## 诚实边界

| 应用 | 自动化程度 | 说明 |
|------|-----------|------|
| foot terminal | ✅ 完全 | Darkman ln -sf + SIGUSR1/SIGUSR2 |
| starship prompt | ✅ 完全 | palette.ansi 语义→ANSI 映射 + Powerline + Nerd Font 图标，跟随 foot 终端 16 色，已运行 shell 即时生效 |
| fish shell | ✅ 完全 | Fish 4.3+ Auto theme（[dark]/[light] + OSC 11），跟随 foot 终端背景色切换 |
| bat | ✅ 完全 | replaceVars 模板 + OSC 11 每次调用检测（新进程），darkman toggle 后下一次 `bat` 自动正确；TTY fallback 通过 fish 函数设置 BAT_THEME |
| yazi | ⚠️ 启动时正确 | replaceVars 模板 + OSC 11 启动检测；持久 TUI 进程，运行中实例不切换（`EMULATOR.light` 是 `RoCell` 一次性写入） |
| kwm/mako/fuzzel/wob/fcitx5/networkmanager-dmenu | ✅ 完全 | Darkman ln -sf + signal/reload |
| GTK 应用 | ✅ 完全 | Select-only + dconf |
| Firefox | ✅ 完全 | userChrome.css + userContent.css + Dark Reader，自动跟随 XDG Portal |
| Spotify | ✅ dark/light | XDG Portal |
| Obsidian | ✅ 完全 | 官方主题 + replaceVars snippet + bootstrap.cjs（Portal 损坏，darkman → nativeTheme） |
| Qt 应用 | ⚠️ 近似 | platformTheme = gtk |
| Trae CN 内部主题 | ✅ 完全 | bootstrap.cjs 监听 mode.txt |
