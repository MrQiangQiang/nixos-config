# AI Agent 架构

## 三层上下文架构 (Progressive Disclosure)

```
AGENTS.md      (<100 行)  项目根目录, agent 始终加载, 只含非推断性规则
docs/          (按需搜索)  项目文档, agent 通过 grep/glob 检索
~/knowledge/   (qmd 搜索)  跨项目知识库, agent 通过 qmd MCP 搜索
```

## MCP 配置 SSOT

```
home/agents/mcp-servers.nix  → programs.mcp.servers (唯一来源)
    │
    ▼  home-manager programs.mcp 模块 (26.05 标准)
    │
home/dev/trae-cn.nix         → traeMcpServers 过滤消费 (writable merge)
home/dev/opencode.nix        → enableMcpIntegration 消费
home/dev/codex.nix           → 手动 transform (filterMcpServer) 消费
```

所有 MCP-capable agent 共享同一份配置, 改一处全生效。

Trae CN 是 VSCode fork, MCP 配置读取 `~/.config/Trae CN/User/mcp.json` (User settings dir,
由 product.json nameLong 决定), 非 `~/.trae-cn/mcp.json` (数据目录, 由 dataFolderName 决定)。
用 home.activation writable merge 保留 IDE 运行时写入能力 (UI 添加的 MCP 服务器)。

## 共享内容 SSOT

```
home/agents/shared.nix + shared/ → commands/skills/agents/rules（Markdown SSOT）
    │
    ▼  各 consumer 通过 home-manager 原生模块选项消费
home/dev/opencode.nix     → context + commands + skills + agents
home/dev/codex.nix        → context + skills（rules 通过 combinedRules 合并进 context）
home/dev/claude-code.nix  → context + rules + commands + agents + skills
```

shared.nix 是 lib 函数模块（非 module option）——多个 consumer 各自 import，Nix 求值缓存复用。
空集时对所有工具零副作用（当前 shared/ 全部为 .gitkeep）。

内容设计遵循 superpowers 原则："Skills name actions, not tools"——技能正文平台无关，
工具特定映射放 references/。CLI 工具支持全局配置，IDE 工具 skills 保持项目级（符合工具设计）。

### agents 跨工具共享矩阵

| 内容 | OpenCode | Claude Code | Codex | Trae CN |
|------|:---:|:---:|:---:|:---:|
| context (AGENTS.md) | ✅ | ✅ | ✅ | ✅ |
| rules | ❌ | ✅ | ❌ | ✅ |
| commands | ✅ | ✅ | ❌ | ✅ |
| skills | ✅ | ✅ | ✅ | ✅ |
| agents | ✅ | ✅ | ❌ | ✅ (Beta) |
| hooks | ❌ | ✅ | ✅ | ✅ |

hooks 虽然三工具支持（OpenCode 除外），但事件数差异 6 倍（Claude ~30 / Codex 10 / Trae 6）、
配置格式三种互不兼容（JSON-in-settings / TOML-inline / versioned-hooks.json）、
hm 模块支持不对称（仅 claude-code 有专用 hooks 选项）。
hooks **不入共享 SSOT**，各工具独立配置。运行时已有兼容机制（Trae 导入 Claude hooks、
Codex hooks.json 解析 Claude 格式）。

**agents 为何不给 Codex：**

| | OpenCode / Claude Code | Codex |
|---|---|---|
| 格式 | Markdown + YAML frontmatter | TOML `[agents.<name>]` + 独立 config_file |
| 内容 | 单层：完整 system prompt 指令 | 双层：description + config_file（含 developer_instructions 等配置） |
| config_file | 不存在此概念 | **可选**（`Option<AbsolutePathBuf>`），含 model/reasoning/sandbox/developer_instructions |

Codex agents 是双层 TOML 结构：`[agents.<name>]` 表声明角色元数据（description + config_file），
config_file 指向独立 TOML 文件承载配置（model/reasoning_effort/developer_instructions 等）。
shared.agents 是单层 markdown（YAML frontmatter + 正文指令），与 Codex 双层结构不可逆转换——
markdown 正文可放入 config_file 的 developer_instructions 字段，但无法反向从 TOML 生成 markdown。

**禁止尝试**从 shared.agents 自动派生 Codex agents（双层→单层不可逆，破坏 SSOT 单向性）。

Codex agents 在 `codex.nix` 中通过 `settings.agents` 直接 TOML 定义。

### rules 为何不给 OpenCode 和 Codex

**OpenCode**（无 rules 概念）：

| | Claude Code / Trae | OpenCode |
|---|---|---|
| 格式 | `.md` 行为指导（`~/.claude/rules/<name>.md`、`~/.trae-cn/user_rules/<name>.md`） | 不存在此概念 |
| 用途 | 持久化行为规则（markdown） | 所有行为指导统一在 `AGENTS.md`（context） |

OpenCode 源码确认：`session/instruction.ts:61` 仅加载 `AGENTS.md`，无 `rules/` 目录读取逻辑。
权限规则走独立 permission system，不是 `.rules` 文件。
hm 模块 `mkRenamedOptionModule rules → context` 如实反映此设计。

**Codex**（.rules 是 Starlark 执行策略，非行为指导）：

| | Claude Code / Trae | Codex |
|---|---|---|
| 格式 | `.md` 行为指导 | `.rules` 文件（Starlark 语法） |
| 用途 | 持久化行为规则 | 命令审批 allow/deny（`prefix_rule()` 等） |

Codex 的 `.rules` 是 Starlark 语法的执行策略文件（`codex-rs/core/src/exec_policy.rs:49-51`），
不是行为指导 markdown。把 markdown 塞进 `.rules` 会产生 Starlark 解析错误。
行为指导统一走 `context` (AGENTS.md)，shared.rules 通过 `combinedRules` 合并进 context。

**两者均为工具本身不支持（非 hm 限制）。**

### commands 为何不给 Codex

| | OpenCode / Claude Code | Codex |
|---|---|---|
| 格式 | `commands/<name>.md` 自定义斜杠命令 | 不存在此概念 |
| 用途 | 用户定义 `/mycommand` 快捷操作 | 内置斜杠命令硬编码在 TUI 二进制中 |

Codex 源码确认：`SlashCommand` 是 Rust 枚举，`config_toml.rs` 无 `commands` 键。
Codex 用 `skills`、`hooks`、`plugins` 做扩展，不用自定义斜杠命令。

**工具本身不支持，非 hm 限制。**

## qmd 知识库

desktop-1 为唯一 qmd 索引节点（BM25 + 向量搜索 + LLM 重排序）。
laptop-1 通过 Tailscale Serve 远程访问，URL 在 mcp-servers.nix 中按主机分叉。
~/.knowledge/ 通过 repos.nix 在所有主机自动 clone，qmd 只索引不存储。

## 为什么用 qmd

- **Karpathy 本人在 llm-wiki.md 推荐 qmd** 作为搜索层
- 完全本地: BM25 + 向量搜索 + LLM 重排序, 无 API key
- 4 个只读 MCP 工具 (query/get/multi_get/status), 职责单一
- 仓库自带 Nix flake, x86_64-linux hash 已验证
- CJK 支持: Qwen3-Embedding-0.6B (119 语言)

## 为什么 qmd 搜索项目文档不搜索代码

- 项目文档需要语义搜索 (如 "VRAM 分配策略是什么"), grep 只能精确匹配
- 代码搜索用 grep/ripgrep (精确、快速、零 VRAM), qmd 专注语义搜索
- 混合索引代码会降低搜索质量 (代码语义与文档语义混杂)

## 为什么不用 agentmemory / Cognee / Mem0

- agentmemory: 过度复杂（Rust 二进制不在 crates.io），信息截断严重
- Cognee: 企业级复杂度（多云部署，多 DB 后端），所有操作需 LLM API key
- Mem0: Graph Memory 锁 Pro 层（$249/mo）
- AGENTS.md + git + qmd 已满足需求，符合低复杂度目标

## 为什么 qmd 是搜索引擎不是记忆系统

- 知识库 = "AI 应该知道什么" (外部注入, 人类策展)
- 记忆 = "AI 经历了什么" (内部连续性, 自动捕获)
- qmd 搜索 = 记忆检索 (Tobi Lütke 的设计: 搜索即记忆, 不需要额外记忆系统)
- agent 通过 filesystem MCP 主动写 wiki 页面 (半自动蒸馏, 信号噪声比远高于自动捕获)

## 多主机策略

desktop-1 是唯一模型推理节点 (Qwen3-Embedding + Reranker + query-expansion, VRAM/CPU)。
其他主机通过 Tailscale Serve 访问 qmd MCP (URL 在 mcp-servers.nix 中由 config.custom.qmd.enable 分叉)。
~/knowledge/ 在所有主机上通过 repos.nix 自动 clone (for Obsidian 浏览, AGENTS.md 读取)。
不推荐多机运行独立 qmd (模型资源重, 索引不一致)。

## 本地 LLM 推理

```
desktop-1: Ollama (CUDA, qwen3.6:27b-q4_K_M)
           host=0.0.0.0 + firewall tailscale0:11434
           syncModels=true (nix 配置是模型清单唯一来源)
           KEEP_ALIVE=-1 + ollama-prewarm.service (永久驻留 VRAM)
laptop-1:  opencode → Ollama via Tailscale（host=0.0.0.0 + firewall tailscale0）
```

VRAM 分配策略详见 `docs/desktop-1/ollama.md`

## 为什么用 Ollama 而非 llama.cpp 直接

- Ollama = llama.cpp 封装 + 模型仓库 + REST API + CLI，集成简单
- OpenAI 兼容端点，agent 一行配置即可接入

## 为什么用 qwen3.6:27b-q4_K_M

- dense 27B 在编码场景优于同规模 MoE 模型，单卡可容纳
- 显式量化 tag 保证 NixOS 可复现性

## 为什么用 syncModels

- 声明式唯一来源: nix 配置 = 实际模型清单
- 未声明模型自动移除, 防止漂移
- 切换模型只需改一行 loadModels

## CLI 工具模型路由（统一代理架构）

```
所有工具 → LiteLLM (localhost:4000) → opencode-go ($10/月, 13模型)
                                      ├── DeepSeek API (按量)
                                      ├── GLM Coding Plan (未来)
                                      └── Ollama (本地, 免费)

协议                                路由
Anthropic Messages  ← Claude Code   /v1/messages
OpenAI Chat         ← OpenCode     /v1/chat/completions
OpenAI Responses    ← Codex        /v1/responses → 自动桥接 Chat
```

全部云端模型（api-providers.nix 维护精确数量）对所有工具可见，运行时按需切换。

## API Provider SSOT + LiteLLM 代理

```
home/agents/api-providers.nix  → providers 注册表 + models 列表（唯一来源）
    │
    ▼  LiteLLM 读取 → 生成 config.yaml → model_list（静态列表，非 wildcard）
home/dev/litellm.nix   → systemd user service (localhost:4000) + 密钥注入
    │
    ▼  所有 consumer 指向同一端点
home/dev/opencode.nix     → provider: litellm（模型列表从 api-providers.nix 派生）+ ollama 后备
home/dev/claude-code.nix  → ANTHROPIC_BASE_URL=localhost:4000
home/dev/codex.nix        → model_provider: litellm（settings.profiles 预留备用）+ codex-oss 后备
```

修改 api-providers.nix → LiteLLM 配置自动更新 → 所有工具立即可用。

### 为什么引入 LiteLLM 代理

- OpenCode Go 套餐全部模型通过 OpenAI Chat 端点可用（已验证 MiniMax/Qwen 同样支持 Chat，Anthropic 端点仅备选）
- Claude Code 无法直连 Chat-only 模型（需要 Anthropic→Chat 转换）
- Codex 0.130+ 强制 Responses API，需要 Responses→Chat 转换
- LiteLLM 单进程运行（不需要 Redis/PostgreSQL，仅 nixpkgs 1.89.0 基础包）
- 配置从 Nix SSOT 自动生成，零手动维护

### 为什么不用 cc-switch-cli

- SQLite DB 配置（非声明式），API key 明文入库，与 agenix 冲突
- 与 NixOS 声明式哲学根本冲突
- LiteLLM 是 2026 NixOS 社区主流方案（NixOS Discourse 实际采用）

### Go 套餐真实性价比

Go 定价含 cache_read（编程 agent 80%+ token 为缓存读取，必须计入）。
**全部 13 个 Go 模型均比同级直连 API 便宜**——Go 的 cache 价格远低于多数官方 API。
具体价格见 api-providers.nix 注释（来源 opencode.ai/docs/zh-cn/go）。

## 模型成本追踪

```
api-providers.nix (SSOT)
  ├── mkModel { input, output, cache_read, cache_write } — 强制每个模型声明 cost
  │   漏写 → Nix 编译失败（利用函数签名做编译时校验）
  │
  ├── opencode-go: Go 套餐官方定价 (opencode.ai/docs/zh-cn/go)
  ├── deepseek:    DeepSeek 直连 API 定价 (api-docs.deepseek.com)
  └── glm-coding-plan: 智谱官方定价 (未订阅，占位)
       │
       ▼ 两个 consumer 各自派生
litellm.nix        — 生成 model_list + api_base（路由用）
opencode.nix       — 生成 models { name, cost }（OpenCode UI spent 显示用）
```

### 三工具成本显示分工

| 工具 | 成本显示 | 来源 |
|---|---|---|
| OpenCode | ✅ TUI spent（$X.XX） | opencode.json → model.cost（从 SSOT 派生） |
| Claude Code | ❌ 仅显示 Anthropic 官方模型价 | 内置定价表，自定义 provider 显示 $0 |
| Codex | ❌ 仅显示 OpenAI 官方模型价 | 内置定价表，自定义 provider 显示 $0 |

**SSOT 在 LiteLLM**：`/spend/logs` + Admin UI 记录所有工具所有模型的真实成本。
Claude Code/Codex 的本地 cost 显示 $0 是预期行为——它们的定价表只覆盖官方模型。

### OpenCode auto-discovery 限制

OpenCode 1.17.7 的 `@ai-sdk/openai-compatible` 不对 `/v1/models` 做 auto-discovery
（`provider.ts:1403`：`models: existing?.models ?? {}`，自定义 provider 不在 models.dev 注册表 → 模型数=0 → provider 被删除）。
因此 opencode.nix 必须显式列出全部模型（从 api-providers.nix 自动派生）。

## 为什么 Claude Code 走代理而非 Anthropic 直连

- 中国无法正常完成 Anthropic OAuth 登录
- 通过 LiteLLM 代理可同时访问 Go 套餐全模型 + DeepSeek API + 本地 Ollama
- 代理处理 Anthropic→Chat 格式转换，Claude Code 无感知
- `hasCompletedOnboarding=true` 跳过 OAuth 登录引导

## 为什么 Codex 走代理而非仅 --oss

- 代理使 Codex 可访问 Go 套餐 13 个云模型（非仅本地）
- LiteLLM 自动桥接 Responses→Chat 以支持 Chat-only 后端
- 保留 `codex-oss` 别名作为代理不可用时的后备


