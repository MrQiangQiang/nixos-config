# 问题跟踪器：本地 Markdown

此仓库的 issue 和规格（你可能知道规格为 PRD）作为 markdown 文件存放在 `.scratch/` 中。

## 约定

- 每个功能一个目录：`.scratch/<feature-slug>/`
- 规格是 `.scratch/<feature-slug>/spec.md`
- 实现的 issue 是每个工单一个文件，位于 `.scratch/<feature-slug>/issues/<NN>-<slug>.md`，从 `01` 开始编号——永远不要一个合并的工单文件
- 分诊状态记录为每个 issue 文件顶部附近的 `Status:` 行（角色字符串见 `triage-labels.md`）
- 评论和对话历史追加到文件底部 `## Comments` 标题下

## 当 skill 说"发布到问题跟踪器"时

在 `.scratch/<feature-slug>/` 下创建一个新文件（如果需要则创建目录）。

## 当 skill 说"获取相关工单"时

读取引用路径处的文件。用户通常会直接传递路径或 issue 编号。

## 寻路操作

由 `/wayfinder` 使用。**地图**是一个文件，每个工单一个**子**文件。

- **地图**：`.scratch/<effort>/map.md`——Notes / Decisions-so-far / Fog 正文。
- **子工单**：`.scratch/<effort>/issues/NN-<slug>.md`，从 `01` 开始编号，正文中包含问题。`Type:` 行记录工单类型（`research`/`prototype`/`grilling`/`task`）；`Status:` 行记录 `claimed`/`resolved`。
- **阻塞**：顶部附近的 `Blocked by: NN, NN` 行。当它列出的每个文件都是 `resolved` 时，工单解除阻塞。
- **前沿**：扫描 `.scratch/<effort>/issues/` 中开放、未阻塞且未认领的文件；编号最小的获胜。
- **认领**：设置 `Status: claimed` 并在任何工作前保存。
- **解决**：在 `## Answer` 标题下追加答案，设置 `Status: resolved`，然后向 `map.md` 中地图的 Decisions-so-far 追加一个上下文指针（gist + 链接）。
