# 模型 Variant 架构

## SSOT

```
home/agents/api-providers.nix  → mkModel { reasoning, reasoningEfforts }
    │                              每个模型声明 variant 能力（唯一来源）
    │
    ▼  消费者自动派生
home/dev/opencode.nix          → model.reasoning = true/false（启用 OpenCode variant 弹窗）
home/agents/codex-model-catalog.nix → supported_reasoning_levels（启用 Codex effort 选择器）
Claude Code                    → 内置网格 UI，无配置（客户端自行处理）
```

## Variant 映射（显示名 ≠ API 实际值）

每个工具用**自己的 naming convention**显示 variant。实际发送给模型的 API 参数值是统一的：

| 选择 | OpenCode 显示 | Codex 显示 | ClaudeCode 显示 | → API reasoning_effort |
|------|:---:|:---:|:---:|:---:|
| 默认 | — | — | — | deployment `extra_body` 默认值 |
| 低 | low | — | low effort | `"low"`（DeepSeek 静默→high） |
| 中 | medium | — | medium effort | `"medium"`（DeepSeek→high） |
| 高 | **high** | **High** | high effort | `"high"` |
| 最高 | **max** | **Extra high** | xHigh/max/ultra | `"max"` / `"xhigh"`（DS: xhigh→max） |

## 每个工具 variant 的来源

| 工具 | variant 显示来源 | 是否模型感知 |
|------|----------------|:---:|
| **OpenCode** | `transform.ts` 按 provider 类型硬编码（`@ai-sdk/openai-compatible` → low/medium/high，deepseek-v4 加 max） | 部分（仅 deepseek-v4 特判） |
| **Codex** | `model-catalog.json` 从 SSOT `reasoningEfforts` 自动生成 | ✅ 完全 |
| **Claude Code** | Claude 固定网格（6 级 effort，始终显示） | ❌ 完全不感知模型 |

## LiteLLM extra_body 合并

```
client reasoning_effort（variant 选择器）
         │
         ▼
litellm utils.py:4336-4338
  final_extra_body = {**deployment_extra_body, **client_extra_body}
         │                   ↑ 默认值              ↑ 用户选择覆盖
         ▼
DeepSeek API 收到 reasoning_effort = 用户选择的值
```

## 关键决策

**为什么 litellm 不生成 variant 模型条目（如 deepseek-v4-pro-max）？**
- Claude Code 已有原生 variant 网格 UI，litellm 条目会造成重复
- OpenCode/Codex 各自客户端处理 variant，不走 litellm model_list
- litellm 只做透传 + 默认值合并

**为什么 opencode 显示 low/medium/high/max 但 low/medium 实际无效？**
- OpenCode `variants()` 按 provider 类型统一生成，不查询模型实际支持
- DeepSeek 内部静默映射 low/medium→high，xhigh→max
- OpenCode 的"统一 UI" 哲学优先于"精确映射"

**为什么 minimax-m3 的 variant 是 none/medium（不是 high/max）？**
- MiniMax-M3 通过 `thinking.type` 控制：disabled（none）或 adaptive（medium）
- 这是 thinking toggle，不是 effort 分级
