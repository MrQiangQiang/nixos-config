
1. **查看当前状态**——merge/rebase 的进度、git 历史和冲突文件。

2. **找到每个冲突的原始来源**。深入理解每处改动的原因和原始意图。阅读 commit message，查看 PR，检查原始 issue/ticket。

3. **逐个 hunk 解决**。尽可能保留双方意图。当无法兼容时，选择匹配 merge 既定目标的一方并记录 trade-off。**不要**发明新行为。始终解决，不要 `--abort`。

4. 发现项目的**自动化检查**并运行——通常是 typecheck，然后 tests，然后 format。修复 merge 破坏的内容。

5. **完成 merge/rebase**。stage 所有内容并 commit。如果是 rebase，继续直到所有 commit 完成 rebase。
