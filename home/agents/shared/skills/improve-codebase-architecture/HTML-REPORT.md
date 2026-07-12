# HTML 报告格式

架构审查渲染为 OS 临时目录中的单个自包含 HTML 文件。Tailwind 和 Mermaid 都来自 CDN。Mermaid 可靠地处理图形状的图表；手工构建的 div 和内联 SVG 处理更编辑性的视觉（质量图、截面）。混合两者 — 不要对一切都依赖 Mermaid，它会开始看起来通用。

## 脚手架

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Architecture review — {{repo name}}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script type="module">
      import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
      mermaid.initialize({ startOnLoad: true, theme: "neutral", securityLevel: "loose" });
    </script>
    <style>
      /* small custom layer for things Tailwind doesn't cover cleanly:
         dashed seam lines, hand-drawn-feeling arrow heads, etc. */
      .seam { stroke-dasharray: 4 4; }
      .leak { stroke: #dc2626; }
      .deep { background: linear-gradient(135deg, #0f172a, #1e293b); }
    </style>
  </head>
  <body class="bg-stone-50 text-slate-900 font-sans">
    <main class="max-w-5xl mx-auto px-6 py-12 space-y-12">
      <header>...</header>
      <section id="candidates" class="space-y-10">...</section>
      <section id="top-recommendation">...</section>
    </main>
  </body>
</html>
```

## 头部

仓库名、日期，和紧凑的图例：实线框 = 模块，虚线 = 接缝，红色箭头 = 泄漏，粗深色框 = 深模块。无介绍段落 — 直入候选。

## 候选卡片

图承担重量。散文稀少、平实，使用术语表术语（来自 `/codebase-design` skill）不加修饰。

每个候选是一个 `<article>`：

- **标题** — 简短，命名深化（如 "Collapse the Order intake pipeline"）。
- **徽章行** — 推荐强度（`Strong` = 翠绿，`Worth exploring` = 琥珀，`Speculative` = 石板灰），加上依赖类别的标签（`in-process`、`local-substitutable`、`ports & adapters`、`mock`）。
- **文件** — 等宽字体列表，`font-mono text-sm`。
- **前/后图** — 核心。两列，并排。见下文模式。
- **问题** — 一句话。什么痛。
- **解决方案** — 一句话。什么改变。
- **收益** — 项目符号，每条 ≤6 个词。如 "Tests hit one interface"、"Pricing logic stops leaking"、"Delete 4 shallow wrappers"。
- **ADR 标注**（如适用）— 琥珀色框中的一行。

无解释段落。如果图需要一段才能理解，重绘图。

## 图表模式

选择适合候选的模式。混合它们。不要让每个图看起来一样 — 多样性是意义的一部分。

### Mermaid 图（依赖/调用流的主力）

当重点是"X 调用 Y 调用 Z，看看这团乱"时用 Mermaid `flowchart` 或 `graph`。用 Tailwind 样式的卡片包裹它，使它不显得突兀。用 classDef 样式将泄漏边着红色、深模块着深色。时序图适合"前：6 次往返；后：1 次"。

```html
<div class="rounded-lg border border-slate-200 bg-white p-4">
  <pre class="mermaid">
    flowchart LR
      A[OrderHandler] --> B[OrderValidator]
      B --> C[OrderRepo]
      C -.leak.-> D[PricingClient]
      classDef leak stroke:#dc2626,stroke-width:2px;
      class C,D leak
  </pre>
</div>
```

### 手工构建的方框和箭头（当 Mermaid 的布局与你对抗时）

模块作为带边框和标签的 `<div>`。箭头作为在相对容器上绝对定位的内联 SVG `<line>` 或 `<path>` 元素。当你想要"后"图感觉像一个粗边框的深模块、内部灰显时用这个 — Mermaid 不会以正确的重量渲染那个。

### 截面（适合分层浅薄）

堆叠水平带（`h-12 border-l-4`）显示调用穿过的层。前：6 个薄层各自什么也不做。后：1 个粗带标注合并后的职责。

### 质量图（适合"接口和实现一样宽"）

每个模块两个矩形 — 一个接口表面积，一个实现。前：接口矩形几乎和实现矩形一样高（浅）。后：接口矩形短，实现矩形高（深）。

### 调用图坍缩

前：渲染为嵌套方框的函数调用树。后：同一棵树坍缩为一个方框，现在内部的调用在其中灰显。

## 样式指南

- 偏编辑性，而非企业仪表板。慷慨的留白。标题可选衬线（`font-serif` 与 stone/slate 搭配良好）。
- 节制用色：一个强调色（翠绿或靛蓝）加红色用于泄漏、琥珀色用于警告。
- 图保持约 320px 高，使前/后并排时无需滚动即可舒适查看。
- 用 `text-xs uppercase tracking-wider` 标记图内模块标签 — 它们应读作示意图，而非 UI。
- 唯一脚本是 Tailwind CDN 和 Mermaid ESM 导入。报告除此之外是静态的 — 无应用代码，无超越 Mermaid 自身渲染的交互性。

## 首要推荐部分

一张更大的卡片。候选名，一句话理由，到其卡片的锚链接。就这样。

## 语气

平实、简洁 — 但架构名词和动词直接来自 `/codebase-design` skill。简洁不是漂移的借口。

**精确使用：** module、interface、implementation、depth、deep、shallow、seam、adapter、leverage、locality。

**绝不替换为：** component、service、unit（替代 module）· API、signature（替代 interface）· boundary（替代 seam）· layer、wrapper（替代 module，当你意指 module 时）。

**符合风格的措辞：**

- "Order intake module is shallow — interface nearly matches the implementation."
- "Pricing leaks across the seam."
- "Deepen: one interface, one place to test."
- "Two adapters justify the seam: HTTP in prod, in-memory in tests."

**收益项目符号**用术语表术语命名收益：*"locality: bugs concentrate in one module"*、*"leverage: one interface, N call sites"*、*"interface shrinks; implementation absorbs the wrappers"*。不要写 *"easier to maintain"* 或 *"cleaner code"* — 那些术语不在术语表中，不配占位。

不含糊，不铺垫，不"it's worth noting that…"。如果一句话可以是项目符号，就做成项目符号。如果一个项目符号可以删，就删。如果一个术语不在 `/codebase-design` 术语表中，在发明新词前先找一个在表中的。
