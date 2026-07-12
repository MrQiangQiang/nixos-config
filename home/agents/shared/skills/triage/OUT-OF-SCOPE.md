# 范围外知识库

仓库中的 `.out-of-scope/` 目录存储被拒绝的功能请求的持久记录。它有两个用途：

1. **制度性记忆** — 记录为何拒绝某个功能，使理由在 issue 关闭后不丢失
2. **去重** — 当新 issue 与先前拒绝匹配时，skill 可以呈现先前的决策，而非重新争论

## 目录结构

```
.out-of-scope/
├── dark-mode.md
├── plugin-system.md
└── graphql-api.md
```

每个**概念**一个文件，而非每个 issue 一个。请求同一内容的多个 issue 归组在同一文件下。

## 文件格式

文件应以轻松、可读的风格编写 — 更像一份简短的设计文档，而非数据库条目。使用段落、代码示例和实例，使推理对首次接触者清晰有用。

```markdown
# Dark Mode

This project does not support dark mode or user-facing theming.

## Why this is out of scope

The rendering pipeline assumes a single color palette defined in
`ThemeConfig`. Supporting multiple themes would require:

- A theme context provider wrapping the entire component tree
- Per-component theme-aware style resolution
- A persistence layer for user theme preferences

This is a significant architectural change that doesn't align with the
project's focus on content authoring. Theming is a concern for downstream
consumers who embed or redistribute the output.

```ts
// The current ThemeConfig interface is not designed for runtime switching:
interface ThemeConfig {
  colors: ColorPalette; // single palette, resolved at build time
  fonts: FontStack;
}
```

## Prior requests

- #42 — "Add dark mode support"
- #87 — "Night theme for accessibility"
- #134 — "Dark theme option"
```

### 文件命名

为概念使用简短、描述性的 kebab-case 名称：`dark-mode.md`、`plugin-system.md`、`graphql-api.md`。名称应足够可识别，使浏览目录的人不解开文件就能理解拒绝了什么。

### 编写理由

理由应有实质内容 — 不是"我们不想要这个"，而是为什么。好的理由会引用：

- 项目范围或哲学（"此项目专注于 X；主题化是下游的关切"）
- 技术约束（"支持此功能需要 Y，这与我们的 Z 架构冲突"）
- 战略决策（"我们选择使用 A 而非 B，因为…"）

理由应持久。避免引用临时情况（"我们现在太忙了"）— 那些不是真正的拒绝，而是推迟。

## 何时检查 `.out-of-scope/`

在分诊期间（步骤 1：收集上下文），阅读 `.out-of-scope/` 中的所有文件。评估新 issue 时：

- 检查请求是否匹配现有的范围外概念
- 匹配按概念相似性，而非关键词 — "night theme" 匹配 `dark-mode.md`
- 如果匹配，呈现给维护者："This is similar to `.out-of-scope/dark-mode.md` — we rejected this before because [reason]. Do you still feel the same way?"

维护者可以：

- **确认** — 新 issue 被添加到现有文件的"Prior requests"列表中，然后关闭
- **重新考虑** — 范围外文件被删除或更新，issue 通过正常分诊流程继续
- **不同意** — issue 相关但不同，通过正常分诊流程继续

## 何时写入 `.out-of-scope/`

仅当 **enhancement**（非 bug）被*拒绝*为 `wontfix` 时。这对 enhancement PR 同样适用 — 被拒绝的 PR 记录在此，使相同请求不会作为新代码卷土重来。

**不要**在因**已实现**而关闭为 `wontfix` 时写入此处。那是已构建的功能，非被拒绝的；记录它会用虚假拒绝污染去重检查。相反，关闭评论指向功能已存在的位置。

流程：

1. 维护者决定某功能请求超出范围
2. 检查是否已存在匹配的 `.out-of-scope/` 文件
3. 如果是：将新 issue 追加到"Prior requests"列表
4. 如果否：创建新文件，包含概念名、决策、理由和首个先前请求
5. 在 issue 上发布评论解释决策，并提及 `.out-of-scope/` 文件
6. 用 `wontfix` 标签关闭 issue

## 更新或删除范围外文件

如果维护者对先前拒绝的概念改变主意：

- 删除 `.out-of-scope/` 文件
- Skill 不需要重新打开旧 issue — 它们是历史记录
- 触发重新考虑的新 issue 通过正常分诊流程继续
