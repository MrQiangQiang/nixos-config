# 开发工具链架构

> Nix + mise + uv · 三层拼图 · 声明式 · AI 高可维护

---

## 设计原则

1. **唯一来源**：每个工具只有一个管理来源，不重复
2. **职责单一**：Nix 管系统，mise 管版本，uv 管 Python 包
3. **简单优雅**：2 文件 2 变更，无 direnv/fnm/nvm/pyenv 等额外工具
4. **面向未来**：新增语言 = 编辑 toolchain.nix → rebuild → mise install
5. **像拼图**：三层独立，通过 `programs.mise.globalConfig` 和 `home.sessionPath` 连接

---

## 核心架构

```
┌─────────────────────────────────────────────────────────┐
│  Nix 层（声明式，不可变）                                 │
│  ┌─────────────────────────────────────────────────────┐│
│  │ programs.mise                                       ││
│  │   .enable = true          → 安装 mise 二进制        ││
│  │   .globalConfig.tools     → 声明全局工具版本        ││
│  │   .globalConfig.settings  → 声明安全策略            ││
│  │   .enableFishIntegration  → fish 中自动 activate    ││
│  │                                                     ││
│  │ home.sessionPath          → shim 目录加入 PATH       ││
│  │ programs.nix-ld           → 预编译二进制兼容         ││
│  └─────────────────────────────────────────────────────┘│
│                         │                               │
│                         ▼                               │
│  mise 层（版本管理，mise.lock 可复现）                    │
│  ┌─────────────────────────────────────────────────────┐│
│  │ 全局工具（由 Nix 声明，mise 安装）                    ││
│  │   python@3.11, 3.12, 3.13, 3.14                     ││
│  │   node@24, go@1.24, zig@0.14, uv@latest             ││
│  │   rust@stable, pipx:ruff@latest                      ││
│  │                                                     ││
│  │ 项目工具（由 mise.toml 声明，mise 安装）              ││
│  │   每个项目的特定版本和依赖                            ││
│  └─────────────────────────────────────────────────────┘│
│                         │                               │
│                         ▼                               │
│  语言包管理器（各语言原生）                               │
│  ┌─────────────────────────────────────────────────────┐│
│  │ Python: uv (venv + pyproject.toml + uv.lock)        ││
│  │ Node:   pnpm (package.json + pnpm-lock.yaml)        ││
│  │ Go:     go mod (go.mod + go.sum)                    ││
│  │ Rust:   cargo (Cargo.toml + Cargo.lock)             ││
│  │ Zig:    build.zig                                   ││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

---

## 为什么是 Nix + mise + uv 而非纯 Nix

| 维度 | 纯 Nix（mitchellh 风格） | Nix + mise + uv |
|------|------------------------|-----------------|
| 声明式 | ✅✅✅ | ✅✅（`programs.mise.globalConfig`） |
| 可复现 | ✅✅✅ bit-for-bit | ✅✅ mise.lock |
| 版本灵活 | ❌ 受 nixpkgs 更新周期限制 | ✅ 任意版本 |
| AI 可维护 | ❌ Nix 语言 | ✅ TOML |
| 非 Nix 协作者 | ❌ 无法使用 | ✅ 可使用 mise.toml |
| 项目样板 | ❌ 每个项目写 flake.nix | ✅ `mise use node@24` 一行 |

纯 Nix 的"完全可复现"在个人桌面场景下是过度设计。`programs.mise.globalConfig` 让声明式等价，但灵活性远超。

---

## 为什么不用 direnv / devenv / proto / pixi

| 工具 | 为什么不用 |
|------|-----------|
| direnv | mise `[env]` 段直接替代，不引入额外工具 |
| devenv / devbox | 在 Nix 上再加一层抽象，违反简单原则 |
| proto | 无 lockfile，致命缺陷 |
| pixi | conda 生态，不是通用 dev toolchain |

---

## 为什么需要 shim

`mise activate` 是 shell hook，只在交互式 shell 的 prompt 显示时触发。非交互式上下文（Trae CN、systemd、GUI 应用）永远不会触发 shell hook。shim 是符号链接，放在 PATH 上，任何上下文都能找到。

| 上下文 | 发现机制 |
|--------|---------|
| 用户终端（fish） | `mise activate fish`（PATH 模式） |
| Trae CN 主进程 | shim（`home.sessionPath`） |
| systemd / cron / GUI 应用 | shim |

shim 不加载 `[env]` 环境变量、不运行 hooks。集成终端中 mise activate 生效，无此限制。

---

## 为什么 Python 用 `"source"` 而非 `"create|source"`

`python.uv_venv_auto = "source"` 只激活已存在的 `.venv`，让 `uv sync` 负责创建。职责更清晰：uv 管 venv 生命周期，mise 管激活。

---

## 为什么用 `node.corepack = true` 而非 `[hooks] enter = "corepack enable"`

| 维度 | hooks 方案 | `node.corepack = true` |
|------|-----------|----------------------|
| 依赖 | Node 内置 Corepack（Node 26+ 可能移除） | mise 直接安装 shims |
| 复杂度 | 需要 `experimental = true` + hook | 一行配置 |
| 失败处理 | `|| true` 静默忽略 | mise 处理 |

Node.js TSC 于 2025 年 3 月投票停止随 Node 分发 Corepack。mise v2026.6.0 的 `node.corepack` 不依赖 Node 内置 Corepack，面向未来。

---

## 为什么 `mise use --global` 不可用

`programs.mise.globalConfig` 生成只读的 `config.toml`，`mise use --global` 会失败。这是**特性**：强制所有全局工具变更通过 .nix 文件，确保声明式和唯一来源。

---

## 全局 CLI 边界规则

| 规则 | 示例 | 管理方式 |
|------|------|---------|
| 语言无关的工具 → Nix | git, ripgrep, fd, bat, jq | `pkgs.xxx` |
| 语言相关的工具 → mise 对应后端 | ruff(Python), tsc(Node) | `pipx:ruff`, `npm:typescript` |
| 绝不用 `pip install --global` 或 `npm install -g` | — | — |

判断标准：这个工具依赖某个特定语言运行时吗？是 → mise，否 → Nix。

---

## Rust 特殊性

mise 委托 rustup 管理 Rust 工具链（`rust = "stable"` 已自说明）。
