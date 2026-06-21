# 快捷键统一架构方案

> River + KWM · 双轨制：托管绑定 + 编目绑定 · 语义注册表 + fuzzel 搜索

---

## 设计原则

1. **唯一来源**：`keybind-registry.nix` 是所有快捷键语义描述的唯一来源
2. **职责单一**：各应用管自己的快捷键配置，注册表只管编目和搜索
3. **简单优雅**：不发明跨应用统一键绑定层，不引入 keyd/xremap 等额外依赖
4. **面向未来**：新增应用 = 在注册表添加条目，无需改架构
5. **像拼图**：每个应用是独立的拼图块，注册表是拼图板
6. **可验证**：注册表与配置的一致性可自动校验，不依赖人工记忆

---

## 核心问题

能否将 kwm、Firefox、Trae CN、foot 等所有软件的快捷键统一到一套按键方案？

**不能也不应该。** 原因：

1. 不同应用的操作域不同（WM 管理窗口，浏览器管理标签），强行统一按键没有意义
2. Firefox 等应用的快捷键硬编码在 C++ 源码中，无法外部改变
3. 统一按键方案意味着 `Super+j` 在不同应用中做不同事，反而增加认知负担

正确方案：**管理可控的，编目不可控的。**

---

## 按键处理四层现实

```
┌─────────────────────────────────────────────────────────┐
│ Layer 0: 硬件重映射层 (keyd / kanata / interception)     │
│   物理键 → 逻辑键  (CapsLock→Esc, CapsLock→Ctrl)       │
│   ✅ 全局生效   ⚠️ 只改映射不改语义                      │
├─────────────────────────────────────────────────────────┤
│ Layer 1: 合成器层 (kwm / River)                          │
│   修饰键+按键 → 窗口管理动作                              │
│   ✅ 完全可控   ← kwm-config.zon 就是这一层              │
├─────────────────────────────────────────────────────────┤
│ Layer 2: 工具包层 (GTK shortcuts / Qt / Electron)        │
│   Ctrl+按键 → 应用动作                                   │
│   ⚠️ 部分可控  (foot/fuzzel 可配置, Firefox 几乎不可控)   │
├─────────────────────────────────────────────────────────┤
│ Layer 3: 应用内部层 (Firefox C++ / VS Code when-clause)  │
│   快捷键硬编码在源码中                                    │
│   ❌ 不可控    (Firefox 的 Ctrl+L 聚焦地址栏无法外部改变) │
└─────────────────────────────────────────────────────────┘
```

每一层有独立的按键处理系统，不存在一个"上帝视角"能统一控制所有层。2026 年社区没有成熟的跨应用快捷键统一管理工具。

---

## 核心架构：双轨制

```
┌───────────────────────────────────────────────────────────────┐
│                    语义注册表 (Semantic Registry)              │
│                    唯一来源：home/desktop/keybind-registry.nix │
│                                                               │
│  ┌─────────────────────┐    ┌──────────────────────────────┐ │
│  │  Managed 托管绑定    │    │  Documented 编目绑定          │ │
│  │                      │    │                              │ │
│  │  Nix 定义 + 生成配置  │    │  Nix 定义 + 仅用于文档       │ │
│  │  ✅ 当前由 Nix 管理   │    │  ⚠️ 可控但当前未管理         │ │
│  │  ✅ 冲突检测          │    │  ✅ 可搜索                   │ │
│  │  ✅ 生成应用配置      │    │  ✅ 冲突预警                 │ │
│  │                      │    │                              │ │
│  │  • kwm               │    │  • conventions（行业约定）   │ │
│  │                      │    │  • fcitx5（输入法快捷键）    │ │
│  │                      │    │  • Firefox（不可控）          │ │
│  │                      │    │  • foot / fuzzel（可控未管理）│ │
│  │                      │    │  • opencode（可控未管理）    │ │
│  │                      │    │  • Trae CN / yazi / vim      │ │
│  └──────────┬───────────┘    └──────────────┬───────────────┘ │
│             │                               │                 │
│             ▼                               ▼                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │              统一速查 / 搜索 / 冲突检测                   │ │
│  │              fuzzel dmenu → Super+/                       │ │
│  └──────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────┘
```

### 为什么双轨制而非完全统一

| 方案 | 问题 |
|------|------|
| 完全统一：所有应用用同一套按键 | Firefox 快捷键不可外部改变；不同应用操作域不同 |
| 完全独立：各管各的，无统一视角 | 用户无法搜索"我想做X该按什么键"，无法发现跨应用冲突 |
| 双轨制 | ✅ 托管当前管理的 + 编目其余的，用户通过 `Super+/` 搜索所有快捷键 |

### 为什么 kwm 快捷键保持 ZON 直写而非抽象为 Nix attrset

kwm 事件是结构化的（`.focus_iter`、`.set_output_tag` 等），不是简单的命令字符串，Nix→ZON 生成器复杂度高、收益低。ZON 格式本身是结构化的，AI 可直接读写理解；注册表只做语义描述，不做配置生成。

### 为什么 conventions 是 documented 而非 managed

Ctrl+C/V 等约定不在 `kwm-config.zon` 中，标记为 "M"（托管）是不诚实的。conventions 标记为 "D"（编目）意味着"我们记录它，但不管理它" — 这正是事实。

### 为什么 opencode 的 `<leader>` 和弦键用 `Leader+N` 表示

opencode 使用 `<leader>` 键（默认 Ctrl+X）实现双键顺序和弦（先按 leader 释放后再按下个键），与注册表的"同时按下"按键模型不同。通过 `mods=[]; key="Leader+n"` 即表示 — 不对现有格式做任何扩展，且不会触发冲突检测误报。

---

## 数据注入模式

注册表遵循 `palette.nix` 的注入模式：

```
home/desktop/keybind-registry.nix  ← 数据源（唯一定义点）
        │
        ▼  home/default.nix 中 import + _module.args.keybinds 注入
        │
home/desktop/keybind-help.nix     ← 消费者：keybinds 作为函数参数
home/desktop/kwm.nix              ← 消费者：keybinds 作为函数参数（未来需要时）
```

### 为什么放在 home/desktop/ 而非 lib/

| 位置 | 职责 | 是否合适 |
|------|------|---------|
| `lib/` | Flake 级构建工具 | ❌ 注册表不是构建工具 |
| `modules/` | NixOS 系统级模块 | ❌ 快捷键是用户级关注点 |
| `home/desktop/` | 用户级桌面数据源和配置 | ✅ 与 `palette.nix` 同层 |

### 为什么通过 _module.args 注入而非各模块自行 import

各模块自行 import 会导致路径分散、无法保证同一实例。`_module.args.keybinds` 与 `palette` 注入方式一致，改位置只改 `home/default.nix` 一处。

### 为什么是用户层而非系统层

快捷键是用户级关注点（不同用户可能需要不同快捷键），不是系统级关注点（硬件、网络、安全策略）。

### 为什么是所有主机共享而非单主机

`isDesktopEnabled` 守卫已确保非桌面主机不加载桌面模块。与 `palette.nix` 一样，注册表放在共享的 `home/desktop/` 中。

---

## 修饰键语义约定

| 修饰键组合 | 语义 | 示例 |
|-----------|------|------|
| `Super` | 主要操作（最常用） | 聚焦、布局、启动器 |
| `Super + Shift` | 破坏性/次要操作 | 关闭、移动、全屏 |
| `Super + Ctrl` | 辅助操作 | 跳过浮动、Sticky |
| `Super + Alt` | 方向/位置操作 | 主区域位置、Float 布局 |
| `Super + Ctrl + Shift` | 窗口级 Tag 操作 | 切换窗口在 Tag 上 |

---

## 冲突检测分层

| 冲突类型 | 严重性 | 处理方式 |
|---------|--------|---------|
| 同一应用内冲突 | 🔴 报错 | Nix assertions 构建时报错 |
| managed 与 documented 应用间 (Super+) | 🟡 预警 | 注册表预警（WM 拦截在前，应用收不到） |
| WM (Super+) 与 documented (Ctrl+) | 🟢 不冲突 | 不同修饰键，不同操作域 |

---

## 速查搜索设计

`Super+/` 触发 fuzzel dmenu 模式，显示所有应用的快捷键：

```
M kwm focus       Super+j       聚焦下一个窗口(focus next)
M kwm app         Print         区域截图(screenshot region)
D conventions edit Ctrl+c       复制(copy)
D fcitx5 ime       Ctrl+Shift+f  简繁切换(simplified traditional toggle)
D firefox nav     Ctrl+l        聚焦地址栏(address bar url)
D foot clipboard  Ctrl+Shift+c  复制(copy)
D opencode session Leader+n      新建会话(session new)
D trae-cn nav     F12           跳转到定义(goto definition)
```

`M` = 托管绑定（可通过 Nix 修改），`D` = 编目绑定（只读文档）。

### 为什么用 fuzzel dmenu

已有 fuzzel，零额外依赖，支持实时搜索过滤。hyprKCS 是 Hyprland 专用，rofi-wayland 功能重叠，eww 配置复杂度高。

### 为什么 Super+/

`/` 暗示"搜索"，是社区标准快捷键（Hyprland/Sway 通用）。

---

## 逐软件可控性

| 软件 | 可控性 | Tier | 说明 |
|------|--------|------|------|
| kwm | ✅ 完全 | managed | ZON 直写，注册表编目 |
| fcitx5 | ✅ 完全 | documented | 配置文件可配置，当前使用默认值 |
| opencode | ✅ 完全 | documented | tui.json 可配置，当前使用默认值 |
| foot | ✅ 完全 | documented | INI 可配置，当前使用默认值 |
| fuzzel | ✅ 完全 | documented | INI 可配置，当前使用默认值 |
| Trae CN | 🟡 大部分 | documented | keybindings.json 可配置 |
| yazi | 🟡 大部分 | documented | keymap.toml 可配置 |
| vim | 🟡 大部分 | documented | .vimrc 映射可配置 |
| conventions | — | documented | 行业约定编目（Ctrl+C/V 等） |
| Firefox | ❌ 不可控 | documented | 快捷键硬编码在 C++ 源码中 |

### Firefox 为什么不可控

快捷键硬编码在 C++ 源码中。`autoconfig.js` + `mozilla.cfg` 只能禁用极少数快捷键，大部分没有暴露为偏好设置。2026 年社区共识：接受 Firefox 默认绑定是最务实的选择。

---

## KWM 默认配置 vs 自定义配置

**原则：不改 kwm 的设计，只加 kwm 没有的。**

| 功能 | config.def.zon（默认） | kwm-config.zon（自定义） | 为什么需要 |
|------|----------------------|------------------------|----------|
| 应用启动器 | `spawn_shell = "wmenu-run"` | `spawn = "fuzzel"` | 我们用 fuzzel 不用 wmenu |
| 锁屏 | 无 | `Super+Shift+L` → `waylock-theme` | kwm 无锁屏绑定 |
| 截图 | 无 | `Print` → `screenshot-region` | kwm 无截图绑定 |
| 取色器 | 无 | `Super+Shift+Print` → `colorpick` | kwm 无取色绑定 |
| 快捷键速查 | 无 | `Super+/` → `keybind-cheatsheet` | kwm 无速查绑定 |
| 切歌 | 无 | `Super+[/]` → `media-prev/next` | 键盘无 XF86_AudioPrev/Next 物理键 |
| 音量/亮度/播放 | 无 | `XF86_Audio*` / `XF86_MonBrightness*` | 笔记本键盘有专用键 |

### 为什么不改 kwm 默认绑定

kwm 的默认快捷键内部自洽（F=Floating 全家桶、Shift=破坏性、Alt=参数调整）。"肌肉记忆优化"看似对齐了其他 WM 的惯例，实际上破坏了 kwm 自身的设计语言。换 WM 时必须重新学习，改 2 个键省不了多少。

---

## 文件结构

```
home/desktop/
  keybind-registry.nix          ← 唯一来源：语义注册表
  keybind-help.nix              ← 速查脚本：keybind-cheatsheet（fuzzel dmenu）
  kwm/config.zon              ← KWM 快捷键配置（直写 ZON）
  kwm.nix                       ← replaceVars 生成 dark/light ZON
  media-keys.nix                ← 音量/亮度/媒体控制脚本
  networkmanager-dmenu.nix      ← WiFi 选择器配置（fuzzel 后端）
  screenshot.nix                ← 截图/取色脚本
  foot.nix                      ← foot 配置
  fuzzel.nix                    ← fuzzel 配置

home/default.nix                ← 注入 keybinds（与 palette 同模式）
```

### 为什么 keybind-help.nix 独立而非放在 kwm.nix 中

kwm.nix 职责是生成 ZON 配置，速查脚本与 ZON 生成无关。未来其他 WM 也可能需要速查。