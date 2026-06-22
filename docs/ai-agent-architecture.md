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
home/dev/trae-cn.nix         → traeMcpServers 过滤消费
home/dev/opencode.nix        → enableMcpIntegration 消费
```

所有 MCP-capable agent 共享同一份配置, 改一处全生效。

## qmd 知识库

```
~/knowledge/                    独立 git 仓库 (Karpathy LLM Wiki 模式)
├── raw/                        人类收集的源文档 (immutable, agent 只读)
│   ├── articles/  papers/  notes/  transcripts/  assets/
└── wiki/                       agent 编译的 wiki (agent 通过 filesystem MCP 写)
    ├── index.md  log.md  concepts/  people/  projects/  tools/

desktop-1: qmd-mcp systemd service (localhost:8181)
           qmd-refresh timer (5min)
           Tailscale Serve proxy (tailscale serve --bg localhost:8181)
           Qwen3-Embedding + Reranker + query-expansion (model inference)
laptop-1:  qmd MCP → https://desktop-1.tail0f7af0.ts.net/mcp (Tailscale Serve)
           URL forks in mcp-servers.nix via config.custom.qmd.enable
```

## 为什么用 qmd

- **Karpathy 本人在 llm-wiki.md 推荐 qmd** 作为搜索层
- 完全本地: BM25 + 向量搜索 + LLM 重排序, 无 API key
- 4 个只读 MCP 工具 (query/get/multi_get/status), 职责单一
- 仓库自带 Nix flake, x86_64-linux hash 已验证
- CJK 支持: Qwen3-Embedding-0.6B (119 语言)

## 为什么不用 agentmemory / Cognee / Mem0

- agentmemory: 39K LOC, 53 MCP 工具, 95% 信息丢失 (8000→400 字符截断), iii-engine Rust 二进制不在 crates.io
- Cognee: 企业级复杂度 (Helm chart, 多云部署, 多 DB 后端), 所有操作需要 LLM API key
- Mem0: Graph Memory 锁 Pro 层 ($249/mo)
- AGENTS.md + git + qmd 已解决跨会话/跨项目/跨机需求, 符合低复杂度目标

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
desktop-1: Ollama (CUDA, qwen3.6:27b-q4_K_M, 256K context, 27.7GB VRAM)
           host=0.0.0.0 + firewall tailscale0:11434
           syncModels=true (nix 配置是模型清单唯一来源)
           KEEP_ALIVE=-1 + ollama-prewarm.service (永久驻留 VRAM)
laptop-1:  opencode → http://desktop-1.tail0f7af0.ts.net:11434/v1 (Tailscale)
```

VRAM 分配策略详见 `docs/desktop-1/ollama.md`

## 为什么用 Ollama 而非 llama.cpp 直接

- Ollama = llama.cpp 封装 + 模型仓库 + REST API + CLI
- 速度差异 <11%, VRAM 开销 +1.2GB (可接受)
- agent 集成简单: OpenAI 兼容端点, opencode 一行配置

## 为什么用 qwen3.6:27b-q4_K_M

- 单卡 RTX 5090 32GB: 17GB 权重 + 10.7GB KV cache (q8_0) = 256K 上下文, 占 27.7GB VRAM
- dense 27B > MoE 35B-A3B (编码场景, SWE-bench 68.9-72.5%)
- 显式量化 tag: NixOS 可复现性, 不受 Ollama 默认变更影响

## 为什么用 syncModels

- 声明式唯一来源: nix 配置 = 实际模型清单
- 未声明模型自动移除, 防止漂移
- 切换模型只需改一行 loadModels

## 源码真理

- `home/agents/mcp-servers.nix` — MCP SSOT
- `home/dev/qmd.nix` — qmd wrapper + MCP service + refresh timer
- `home/dev/opencode.nix` — opencode + Ollama provider
- `home/default.nix` — imports `./agents`
- `flake.nix` — `qmd.url = "github:tobi/qmd"`
