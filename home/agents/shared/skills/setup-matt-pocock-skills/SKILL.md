
# 设置 Matt Pocock 的 skill

脚手架工程 skill 假设的每仓库配置：

- **问题跟踪器**——issue 存放的地方（默认 GitHub；本地 markdown 也开箱即用）
- **分诊标签**——用于五个规范分诊角色的字符串
- **领域文档**——`CONTEXT.md` 和 ADR 存放的地方，以及阅读它们的消费者规则

这是一个提示驱动的 skill，而非确定性脚本。探索、展示你发现的、与用户确认，然后写入。

## 流程

### 1. 探索

查看当前仓库以了解其起始状态。读取存在的任何东西；不要假设：

- `git remote -v` 和 `.git/config`——这是一个 GitHub 仓库吗？哪个？
- 仓库根目录的 `AGENTS.md` 和 `CLAUDE.md`——任一存在吗？任一中是否已经有 `## Agent skills` 章节？
- 仓库根目录的 `CONTEXT.md` 和 `CONTEXT-MAP.md`
- `docs/adr/` 和任何 `src/*/docs/adr/` 目录
- `docs/agents/`——此 skill 的先前输出是否已存在？
- `.scratch/`——本地 markdown 问题跟踪器约定已使用的标志
- `triage` skill 是否已安装？（与此并排的 `triage` skill 文件夹，或你可用 skill 中的 `triage`。）这决定 B 节是否运行。
- Monorepo 信号——`pnpm-workspace.yaml`、`package.json` 中的 `workspaces` 字段，或填充的 `packages/*` 及其自己的 `src/`。仅在真正大型多包仓库中呈现；它们的缺失意味着单上下文，这几乎是每个仓库。

### 2. 展示发现并询问

总结存在的和缺失的。然后按顺序处理各节——一节一个答案，然后下一节。

每节以推荐答案开头，以便用户可以用一个词接受。仅在选择真正分支时给出一行解释；当探索已经解决时完全跳过该节（B 节当 `triage` 未安装时，C 节当没有 monorepo 时）。

**A 节——问题跟踪器。**

> 解释：问题跟踪器是此仓库的 issue 存放的地方。像 `to-tickets`、`triage`、`to-spec` 和 `qa` 这样的 skill 从中读取和写入——它们需要知道是调用 `gh issue create`、在 `.scratch/` 下写一个 markdown 文件，还是遵循你描述的其他工作流。选择你实际用于此仓库跟踪工作的地方。

默认姿态：这些 skill 为 GitHub 设计。如果 `git remote` 指向 GitHub，提议那个。如果 `git remote` 指向 GitLab（`gitlab.com` 或自托管主机），提议 GitLab。否则（或如果用户偏好），提供：

- **GitHub**——issue 存放在仓库的 GitHub Issues 中（使用 `gh` CLI）
- **GitLab**——issue 存放在仓库的 GitLab Issues 中（使用 [`glab`](https://gitlab.com/gitlab-org/cli) CLI）
- **本地 markdown**——issue 作为文件存放在此仓库的 `.scratch/<feature>/` 下（适合个人项目或没有远程的仓库）
- **其他**（Jira、Linear 等）——请用户用一段话描述工作流；skill 将其作为自由格式文本记录

将选择记录在 `docs/agents/issue-tracker.md` 中。GitHub 和 GitLab 模板带有"PR 作为请求面"标志，默认**关闭**——保持关闭且不要提出它；一个想要外部 PR 进入分诊队列的用户可以稍后在文件中翻转标志。

**B 节——分诊标签词汇表。** 如果 `triage` skill 未安装（探索告诉你），完全跳过此节——未安装的 skill 不需要标签。

如果已安装，只问一个问题：

> 你想保留默认分诊标签吗？（推荐：**是**）

默认值是五个规范角色，每个标签字符串等于其名称：`needs-triage`、`needs-info`、`ready-for-agent`、`ready-for-human`、`wontfix`。在**是**上，按原样写入。仅当用户说否——通常因为他们的跟踪器已使用其他名称（例如 `bug:triage` 代替 `needs-triage`）——收集覆盖，使 `triage` 应用现有标签而非创建重复。

**C 节——领域文档。** 默认**单上下文**——仓库根目录的一个 `CONTEXT.md` + `docs/adr/`。这几乎适合每个仓库；无需询问直接写入。

仅当探索发现 monorepo 信号时提供**多上下文**——根 `CONTEXT-MAP.md` 指向每上下文的 `CONTEXT.md` 文件。然后确认他们想要哪种布局。

### 3. 确认和编辑

向用户展示以下草稿：

- 要添加到正在编辑的 `CLAUDE.md` / `AGENTS.md` 的 `## Agent skills` 块（选择规则见步骤 4）
- `docs/agents/issue-tracker.md`、`docs/agents/domain.md` 和 `docs/agents/triage-labels.md` 的内容（最后一个仅当 `triage` 已安装时）

让他们在写入前编辑。

### 4. 写入

**选择要编辑的文件：**

- 如果 `CLAUDE.md` 存在，编辑它。
- 否则如果 `AGENTS.md` 存在，编辑它。
- 如果都不存在，询问用户要创建哪一个——不要替他们选择。

当 `CLAUDE.md` 已存在时永远不要创建 `AGENTS.md`（反之亦然）——始终编辑已经在那里的那个。

如果选择的文件中已存在 `## Agent skills` 块，原地更新其内容而非追加重复。不要覆盖用户对周围章节的编辑。

该块：

```markdown
## Agent skills

### Issue tracker

[one-line summary of where issues are tracked]. See `docs/agents/issue-tracker.md`.

### Triage labels

[one-line summary of the label vocabulary]. See `docs/agents/triage-labels.md`.

### Domain docs

[one-line summary of layout — "single-context" or "multi-context"]. See `docs/agents/domain.md`.
```

仅当 `triage` 已安装且 B 节运行时才包含 `### Triage labels` 子块，并写入 `docs/agents/triage-labels.md`。当未安装时，两者都省略。

然后使用此 skill 文件夹中的种子模板作为起点写入文档文件：

- [issue-tracker-github.md](./issue-tracker-github.md)——GitHub 问题跟踪器
- [issue-tracker-gitlab.md](./issue-tracker-gitlab.md)——GitLab 问题跟踪器
- [issue-tracker-local.md](./issue-tracker-local.md)——本地 markdown 问题跟踪器
- [triage-labels.md](./triage-labels.md)——标签映射（仅当 `triage` 已安装时）
- [domain.md](./domain.md)——领域文档消费者规则 + 布局

对于"其他"问题跟踪器，使用用户的描述从头编写 `docs/agents/issue-tracker.md`。

### 5. 完成

告诉用户设置已完成，以及哪些工程 skill 现在将从这些文件读取。提及他们可以稍后直接编辑 `docs/agents/*.md`——仅在想要切换问题跟踪器或从头重新开始时才需要重新运行此 skill。
