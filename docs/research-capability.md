# 研究调研能力

跨 agent（OpenCode/Claude Code/Codex/Trae）的系统性技术调研能力。

## 三层架构

```
研究 skill (共享 SSOT)     → 方法指导：background agent 调研 primary sources
MCP 服务器 (programs.mcp)  → 知识库搜索：qmd（全网搜索由 agent 原生工具提供）
模型策略                   → 成本优化：flash 搜索/浏览 → pro+max reasoning 综合
```

## 为什么不是单一工具

| 方案 | 覆盖范围 | 跨 agent | 质量 |
|------|---------|:---:|------|
| curl API（仅 shell） | 已知 URL 的 API | ✅ | 无搜索发现 |
| agent 原生 web search | 全网 | ❌ 各自实现 | 好 |
| **skill + qmd MCP（本方案）** | **全网 + 知识库** | ✅ | **最佳** |

纯 curl 方案无搜索发现能力。skill 做方法指导（SSOT），qmd MCP 做知识库语义搜索，全网搜索由各 agent 原生工具提供。三者解耦：方法论一次编写到处使用，知识库跨 agent 共享，web 搜索利用 agent 原生能力。

## 为什么两阶段模型策略

搜索/浏览阶段 token 消耗大但推理需求低 → deepseek-v4-flash（$0.14/1M input）。综合/分析阶段需深度推理 → deepseek-v4-pro + max reasoning（$1.74/1M）。比全程用 pro 省 92% 搜索阶段成本。执行方式：用子代理（OpenCode `task` / 各 agent subagent）指定不同模型。

## 为什么 skill 而非独立应用

skill 在现有 agent 内执行，利用已有模型基础设施（LiteLLM）和项目上下文（grep/qmd），零额外部署。gpt-researcher v0.15.1 已分发为 Claude Skill（`npx skills add assafelovic/gpt-researcher`），验证了"研究能力即 skill"的方向，但本方案不引入外部依赖，保持自包含。

## 上下文占用策略

常驻上下文越短，模型遵循越可靠（ECC/Superpowers 源码验证）。少即是多。

| 层 | 加载时机 | 当前量 | 上限/原则 |
|----|---------|--------|----------|
| context (guidelines) | 每次对话常驻 | 34 行 | **硬性 ≤100 行**；仅行为准则，禁放方法论 |
| skill description | 常驻 catalog | 1 条 (~30 tok) | 保持个位数；多了不触发也占 context 且选择过多导致触发不准 |
| skill body | 按需触发 | ~8 行 | 触发时才加载，不计入常驻 |
| MCP tool schema | 每会话常驻 | 1 server (4 tools, ~2K tok) | 新增必须通过 ECC 两轮测试（Universal + beats CLI） |

**当前常驻总量**：~2.1K tokens（guidelines ~50 + skill desc ~30 + MCP schema ~2K），远低于单次对话预算的 1%。

核心原则：
- **context 硬性 ≤100 行**——方法论放 skill 不放 context
- **skill/MCP 少即是多**——不触发也占 context，选择过多导致模型无法准确触发
- Trae 的 user_rules 是常驻 context，skills 是按需加载——两者不可混用
