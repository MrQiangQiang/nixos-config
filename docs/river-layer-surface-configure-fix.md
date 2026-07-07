# River Layer Surface Configure 修复

> mako 通知在 size 变化后卡死不显示，根因为 river 0.4.5 上游 bug

---

## 根本原因

river 0.4.5 的 `LayerShellOutput.zig` `sendConfigures` 函数（commit 39b11b1d, Isaac Freund, 2025-12-20）将跳过条件从 `!initialized` 改为 `!mapped and !initial_commit`。

该条件过于宽泛：wlr-layer-shell 协议要求客户端 commit（无 buffer）后合成器必须发送 configure 事件，但新条件在此场景下 `!mapped` 为真（无 buffer 不 map）且 `!initial_commit` 也为真（非首次 commit），导致 `continue` 跳过 configure 发送。

sway 的 `layer_shell.c` 仍使用 `!initialized`，不受影响。

## 触发场景

mako 渲染通知时若发现 size 需变化（如加载图片后高度从 68→90），执行 `set_size + commit`（无 buffer）后等待 configure。river 因上述 bug 跳过 configure，mako 永久等待，通知卡死。

## 修复方案

patch 将条件改回 `!initialized`，与 sway 实现一致，符合协议规范。

```
packages/river/layer-surface-configure-fix.patch
```

## 何时移除

river 上游修复此 bug 后（main 分支截至 2026-07-07 未修复），可移除 patch。
