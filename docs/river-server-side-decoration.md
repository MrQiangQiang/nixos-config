# River 服务端装饰协议

> GTK3 应用在 River + kwm 下不渲染 CSD 标题栏，由 kwm 统一绘制边框

---

## 根本原因

GTK3 的 `gdk_wayland_display_prefers_ssd()` **只检查 `org_kde_kwin_server_decoration`**（KDE 废弃协议），**不识别 `zxdg_decoration_manager_v1`**（标准协议）。

River 只广播 `zxdg_decoration_manager_v1` → GTK3 不绑定 → `prefers_ssd()` 永远返回 FALSE → GTK3 创建 CSD decoration widget → CSD 标题栏与 kwm 边框叠加 → 视觉双重。

GTK4 使用 `zxdg_decoration_manager_v1`，不受影响。

---

## 方案

在 River 中添加 `org_kde_kwin_server_decoration` 协议支持。这是所有主流 Wayland 合成器的行业标准做法：Hyprland、Labwc、wayfire、KWin、Ghostty 均实现此协议。

```
River 广播 org_kde_kwin_server_decoration_manager（全局对象）
        ↓
GTK3 绑定 → server_decoration_manager != NULL
        ↓
River 发送 default_mode(Server) → server_decoration_mode = MODE_SERVER
        ↓
gdk_wayland_display_prefers_ssd() → TRUE
        ↓
gtk_window_should_use_csd() → FALSE
        ↓
create_decoration() 不执行 → 无 CSD decoration widget
        ↓
kwm 边框独占 → 消除 CSD 标题栏与 kwm 边框的视觉叠加
```

---

## 为什么这样做

### 方案对比

| 方案 | 问题 |
|------|------|
| GTK CSS 隐藏 CSD | hack，需逐应用维护，CSS 选择器随 GTK 版本变化 |
| `GTK_CSD=0` 环境变量 | 在 GTK3 3.24.52 上不生效，不可靠 |
| `MOZ_GTK_TITLEBAR_DECORATION = "none"` | Firefox 的 `SetCustomTitlebar()` 提前返回，不调用 `gtk_window_set_decorated(false)`，GTK3 仍渲染默认 CSD |
| 补丁 GTK3 源码 | 编译 GTK3 需要 8h+，每次 nixpkgs 更新都需重新编译 |
| kwm 强制 SSD（`kwm-respect-ssd-rules.patch`） | Firefox 声明 `only_supports_csd`，强制 SSD 导致关闭按钮消失 |
| **River 广播 KDE 协议** | ✅ 协议层方案，GTK3 源码本就支持，零应用层 hack |

### 为什么协议虽废弃仍使用

`org_kde_kwin_server_decoration` 被 KDE 废弃，由 `zxdg_decoration_manager_v1` 取代。但 GTK3 源码只认前者——这是 GTK3 上游的实现决定，不是 compositor 可以选择的。所有主流 compositor 都同时实现两个协议，各管各的客户端。

当 GTK3 未来支持 `zxdg_decoration_manager_v1` 时，此协议自动成为无害的 no-op。

---

## 实现

### 文件变更

| 操作 | 文件 | 说明 |
|------|------|------|
| **新建** | `packages/river/kde-server-decoration.patch` | 单一 patch：协议 XML + ServerDecoration.zig + build.zig + Server.zig + main.zig |
| **修改** | `packages/river.nix` | `patches = [ ./river/kde-server-decoration.patch ]` |
| **修改** | `modules/desktop.nix` | `MOZ_GTK_TITLEBAR_DECORATION = "system"` — 告诉 Firefox 请求 SSD 而非跳过装饰（`"none"` 会导致 GTK3 仍渲染默认 CSD） |
| **修改** | `home/desktop/firefox.nix` | `browser.tabs.inTitlebar = 1` — KDE 协议生效后 GTK3 不画 CSD，tabs 占据顶部边缘不留空白；移除旧 `MOZ_GTK_TITLEBAR_DECORATION = "none"` |
| **修改** | `home/desktop/kwm/config.zon` | 移除 Firefox `.decoration = .ssd` 规则（不再需要 kwm 层强制） |

### patch 结构

```
river-kde-server-decoration.patch
├── protocol/upstream/server-decoration.xml    ← 协议 XML（52 行）
├── river/ServerDecoration.zig                 ← 协议实现（~110 行）
├── river/Server.zig                           ← 4 处修改：import、字段、init、allowlist
├── river/main.zig                             ← 1 处修改：LogScope 枚举
└── build.zig                                  ← 2 处修改：addCustomProtocol、generate
```

### ServerDecoration.zig 核心逻辑

- 创建 `org_kde_kwin_server_decoration_manager` 全局对象
- 客户端绑定时立即发送 `default_mode(Server)`
- 客户端 `create(decoration, surface)` 时创建 per-surface 对象并发送 `mode(Server)`
- 忽略客户端 `request_mode`（River 总是 SSD，compositor 是装饰决策的权威）
- 遵循 River 现有代码模式（`wl.Global.create` → `setHandler` → `wl.list.Head`）

### zig-wayland Scanner 命名空间

Scanner 的 `prefix()` 函数取第一个 `_` 之前的部分，所以 `org_kde_kwin_server_decoration_manager` → 命名空间 `org`，类型名 `KdeKwinServerDecorationManager`。导入路径为 `@import("wayland").server.org`。

---

## 与 kwm swallow 双边框的关系

kwm 的 `auto_swallow` 产生的双边框（主边框 + `swallowing_border`）是 kwm 的**有意设计**——同时传达焦点状态和吞咽状态。本方案不涉及此行为。

本方案解决的是**另一层问题**：GTK3 自绘 CSD 标题栏 + kwm 边框的视觉叠加。两者互不干扰。

---

## 设计原则

| 原则 | 验证 |
|------|------|
| **简单** | 单一 patch，~110 行 Zig + 52 行 XML，无外部依赖 |
| **优雅** | Compositor 告诉客户端"我负责装饰"，客户端遵从——正确的 Wayland 架构 |
| **职责单一** | River 管协议协商，kwm 管边框渲染，GTK3 管内容——各司其职 |
| **唯一来源** | River 是装饰决策的唯一来源，GTK3 只是遵从 |
| **低复杂度** | 遵循 River 现有代码模式（XkbConfig、IdleInhibitManager 风格），不引入新架构概念 |
| **面向未来** | 协议稳定无 breaking change；GTK3 未来支持标准协议后自动成为 no-op |
| **像拼图** | 一个自包含模块，嵌入 River 架构不触碰任何其他子系统 |
| **编译快** | 只重新编译 River，分钟级 |
