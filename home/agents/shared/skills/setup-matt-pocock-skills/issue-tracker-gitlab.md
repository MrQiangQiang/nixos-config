# 问题跟踪器：GitLab

此仓库的 issue 和 PRD 作为 GitLab issue 存放。所有操作使用 [`glab`](https://gitlab.com/gitlab-org/cli) CLI。

## 约定

- **创建 issue**：`glab issue create --title "..." --description "..."`。多行描述使用 heredoc。传递 `--description -` 打开编辑器。
- **读取 issue**：`glab issue view <number> --comments`。使用 `-F json` 获取机器可读输出。
- **列出 issue**：`glab issue list -F json` 配合适当的 `--label` 过滤器。
- **评论 issue**：`glab issue note <number> --message "..."`。GitLab 将评论称为"notes"。
- **添加/移除标签**：`glab issue update <number> --label "..."` / `--unlabel "..."`。多个标签可以逗号分隔或通过重复标志。
- **关闭**：`glab issue close <number>`。`glab issue close` 不接受关闭评论，所以先用 `glab issue note <number> --message "..."` 发布解释，然后关闭。
- **Merge request**：GitLab 将 PR 称为"merge request"。使用 `glab mr create`、`glab mr view`、`glab mr note` 等——与 `gh pr ...` 形状相同，用 `mr` 代替 `pr`，用 `note`/`--message` 代替 `comment`/`--body`。

从 `git remote -v` 推断仓库——`glab` 在克隆内运行时自动执行此操作。

## Merge request 作为分诊面

**MR 作为请求面：否。** _（如果此仓库将外部 merge request 视为功能请求，设为 `yes`；`/triage` 读取此标志。）_

设为 `yes` 时，MR 使用与 issue 相同的标签和状态，使用 `glab mr` 等价物：

- **读取 MR**：`glab mr view <number> --comments` 和 `glab mr diff <number>` 获取 diff。
- **列出用于分诊的外部 MR**：`glab mr list -F json`，然后只保留作者不是项目成员/所有者的 MR（贡献者的 MR，而非维护者进行中的工作）。
- **评论/标签/关闭**：`glab mr note`、`glab mr update --label`/`--unlabel`、`glab mr close`。

与 GitHub 不同，GitLab 分别为 issue 和 MR 编号，所以 `#42` 一旦你知道维护者指的是哪个面就是明确的。

## 当 skill 说"发布到问题跟踪器"时

创建一个 GitLab issue。

## 当 skill 说"获取相关工单"时

运行 `glab issue view <number> --comments`。

## 寻路操作

由 `/wayfinder` 使用。**地图**是一个 issue，**子** issue 作为工单。

- **地图**：一个标记为 `wayfinder:map` 的 issue，持有 Notes / Decisions-so-far / Fog 正文。`glab issue create --label wayfinder:map`。（在有原生 epic 的 GitLab 层级上，epic 可以代替持有地图；一个标记的 issue 在所有地方都可用。）
- **子工单**：在描述顶部带有 `Part of #<map>` 和标签 `wayfinder:<type>`（`research`/`prototype`/`grilling`/`task`）的 issue。一旦被认领，工单被分配给驱动的开发者。
- **阻塞**：GitLab 的**原生阻塞链接**——规范的、UI 可见的表示。用 `/blocked_by #<n>` 快速操作添加它，作为 note 发布（`glab issue note <child> --message "/blocked_by #<blocker>"`）。原生阻塞链接是 Premium/Ultimate 功能；在免费层级（或不可用时）回退到描述顶部的 `Blocked by: #<n>, #<n>` 行。当每个阻塞者都被关闭时，工单解除阻塞。
- **前沿查询**：`glab issue list -F json` 范围限定到地图的子项，丢弃任何有开放阻塞者——一个到开放 issue 的原生 `blocked_by` 链接（`glab api projects/:id/issues/:iid/links`），或 `Blocked by` 行中的开放 issue——或分配者的；地图顺序中第一个获胜。
- **认领**：`glab issue update <n> --assignee @me`——会话的第一次写入。
- **解决**：`glab issue note <n> --message "<answer>"`，然后 `glab issue close <n>`，然后向地图的 Decisions-so-far 追加一个上下文指针（gist + 链接）。
