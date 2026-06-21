# Firefox Rose Pine 主题 — 变量映射参考

> 本文档是 `rose-pine-theme-plan.md` 的配套参考，记录所有 CSS 变量到 Rose Pine 调色板的映射。
> 架构决策和"为什么"在主文档中，本文档只记录"是什么"。

## userChrome.css — Chrome UI 变量映射

### `:root` 设计令牌覆盖

| 分类 | Firefox 变量 | 覆盖值 | 影响组件 |
|------|-------------|--------|---------|
| **Canvas/Box** | `--background-color-canvas` | `var(--rp-base)` | 全局画布背景 |
| | `--background-color-box` | `var(--rp-surface)` | 卡片/面板内框 |
| | `--background-color-dimmed` | `var(--rp-highlight-low)` | hover 背景 |
| | `--background-color-dimmed-further` | `var(--rp-highlight-med)` | active 背景 |
| **Text** | `--text-color` | `var(--rp-text)` | 主文字 |
| | `--text-color-deemphasized` | `var(--rp-subtle)` | 次要文字 |
| **Border** | `--border-color` | `var(--rp-highlight-med)` | 主边框 |
| | `--border-color-deemphasized` | `var(--rp-highlight-low)` | 次要边框 |
| | `--card-border-color` | `var(--rp-highlight-med)` | 卡片边框 |
| | `--card-background-color` | `var(--rp-surface)` | 卡片背景 |
| **Frame** | `--toolbox-background-color` | `var(--rp-base)` | 导航工具箱 |
| | `--toolbox-text-color` | `var(--rp-text)` | 工具箱文字 |
| | `--toolbox-background-color-inactive` | `var(--rp-surface)` | 非活跃窗口 |
| | `--toolbox-text-color-inactive` | `var(--rp-subtle)` | 非活跃文字 |
| **Toolbar** | `--toolbar-background-color` | `var(--rp-surface)` | 工具栏/书签栏 |
| | `--toolbar-text-color` | `var(--rp-text)` | 工具栏文字 |
| **Toolbar Buttons** | `--toolbarbutton-icon-fill` | `var(--rp-subtle)` | 图标默认色 |
| | `--toolbarbutton-icon-fill-attention` | `var(--rp-rose)` | 图标强调色 |
| | `--toolbarbutton-icon-fill-attention-text` | `var(--rp-base)` | 强调图标上文字 |
| | `--toolbarbutton-background-color-hover` | `var(--rp-highlight-low)` | 按钮 hover |
| | `--toolbarbutton-background-color-active` | `var(--rp-highlight-med)` | 按钮 active |
| | `--toolbarseparator-color` | `var(--rp-highlight-med)` | 工具栏分隔线 |
| **URL Bar** | `--toolbar-field-background-color` | `var(--rp-overlay)` | 地址栏背景 |
| | `--toolbar-field-background-color-focus` | `var(--rp-overlay)` | 地址栏聚焦背景 |
| | `--toolbar-field-text-color` | `var(--rp-text)` | 地址栏文字 |
| | `--toolbar-field-text-color-focus` | `var(--rp-text)` | 地址栏聚焦文字 |
| | `--toolbar-field-border-color` | `var(--rp-highlight-med)` | 地址栏边框 |
| | `--toolbar-field-border-color-focus` | `var(--rp-rose)` | 地址栏聚焦边框 |
| **URL Bar Box** | `--urlbar-box-background-color` | `var(--rp-highlight-low)` | 身份框背景 |
| | `--urlbar-box-background-color-focus` | `var(--rp-highlight-low)` | 身份框聚焦 |
| | `--urlbar-box-background-color-hover` | `var(--rp-highlight-med)` | 身份框 hover |
| | `--urlbar-box-background-color-active` | `var(--rp-highlight-med)` | 身份框 active |
| | `--urlbar-box-text-color` | `var(--rp-text)` | 身份框文字 |
| | `--urlbar-box-text-color-hover` | `var(--rp-text)` | 身份框 hover 文字 |
| **URL Bar View** | `--urlbarview-background-color-hover` | `var(--rp-highlight-low)` | 结果行 hover |
| | `--urlbarview-background-color-selected` | `var(--rp-highlight-med)` | 结果行选中 |
| | `--urlbarview-text-color-selected` | `var(--rp-text)` | 选中文字 |
| | `--urlbarview-text-color-action` | `var(--rp-iris)` | 动作标签 |
| | `--urlbarview-separator-color` | `var(--rp-highlight-low)` | 分隔线 |
| | `--urlbarView-secondary-text-color` | `var(--rp-subtle)` | URL 辅助文字 |
| **Tabs** | `--tab-background-color-selected` | `var(--rp-surface)` | 选中标签背景 |
| | `--tab-background-color-hover` | `var(--rp-highlight-low)` | 标签 hover |
| | `--tab-selected-textcolor` | `var(--rp-text)` | 选中标签文字 |
| | `--tab-loading-fill` | `var(--rp-foam)` | 加载指示器 |
| | `--tab-attention-dot-color` | `var(--rp-foam)` | 注意力点 |
| | `--tab-min-height` | `36px` | 标签最小高度 |
| | `--tab-border-color-accent` | `var(--rp-rose)` | Nova 渐变边框 |
| | `--tab-border-color-selected-leading` | `var(--rp-rose)` | Nova 前导边框 |
| | `--tab-border-color-selected-trailing` | `var(--rp-iris)` | Nova 尾随边框 |
| | `--tab-selected-shadow` | `none` | Nova 选中阴影 |
| **Panel** | `--panel-background-color` | `var(--rp-base)` | 面板背景 |
| | `--panel-background-color-dimmed` | `var(--rp-highlight-low)` | 面板 hover |
| | `--panel-background-color-dimmed-further` | `var(--rp-highlight-med)` | 面板 active |
| | `--panel-text-color` | `var(--rp-text)` | 面板文字 |
| | `--panel-border-color` | `var(--rp-highlight-med)` | 面板边框 |
| **Sidebar** | `--sidebar-background-color` | `var(--rp-surface)` | 侧边栏背景 |
| | `--sidebar-text-color` | `var(--rp-text)` | 侧边栏文字 |
| | `--sidebar-border-color` | `var(--rp-highlight-low)` | 侧边栏边框 |
| **Buttons** | `--button-background-color` | `var(--rp-overlay)` | 按钮背景 |
| | `--button-background-color-hover` | `var(--rp-highlight-low)` | 按钮 hover |
| | `--button-background-color-active` | `var(--rp-highlight-med)` | 按钮 active |
| | `--button-text-color` | `var(--rp-text)` | 按钮文字 |
| | `--button-text-color-primary` | `var(--rp-base)` | 主按钮文字 |
| | `--button-background-color-primary` | `var(--rp-rose)` | 主按钮背景 |
| | `--color-accent-primary` | `var(--rp-rose)` | 全局强调色 |
| | `--color-accent-primary-hover` | `var(--rp-rose)` | 强调色 hover |
| | `--color-accent-primary-active` | `var(--rp-rose)` | 强调色 active |
| **Ghost Buttons** | `--button-background-color-ghost` | `transparent` | 面板按钮背景 |
| | `--button-background-color-ghost-hover` | `var(--rp-highlight-low)` | 面板按钮 hover |
| | `--button-background-color-ghost-active` | `var(--rp-highlight-med)` | 面板按钮 active |
| | `--button-text-color-ghost` | `var(--rp-subtle)` | 面板按钮文字 |
| | `--button-text-color-ghost-hover` | `var(--rp-text)` | 面板按钮 hover 文字 |
| | `--button-text-color-ghost-active` | `var(--rp-text)` | 面板按钮 active 文字 |
| **Links/Focus** | `--link-color` | `var(--rp-iris)` | 链接色 |
| | `--link-color-hover` | `var(--rp-iris)` | 链接 hover |
| | `--link-color-active` | `var(--rp-iris)` | 链接 active |
| | `--focus-outline-color` | `var(--rp-rose)` | 焦点轮廓 |
| | `--color-accent-attention` | `var(--rp-foam)` | 注意力强调 |
| | `--color-accent-primary-selected` | `var(--rp-rose)` | 选中强调 |
| | `--icon-color` | `var(--rp-subtle)` | 通用图标 |
| **Input (legacy)** | `--input-color` | `var(--rp-text)` | global-shared.css input |
| | `--input-bgcolor` | `var(--rp-overlay)` | global-shared.css input 背景 |
| | `--input-border-color` | `var(--rp-highlight-med)` | global-shared.css input 边框 |
| **Input (new)** | `--input-text-background-color` | `var(--rp-overlay)` | moz-input-search 背景 |
| | `--input-text-color` | `var(--rp-text)` | moz-input-search 文字 |
| | `--input-text-border-color` | `var(--rp-highlight-med)` | moz-input-search 边框 |
| | `--input-text-border` | `var(--border-width) solid var(--rp-highlight-med)` | moz-input-search 完整边框 |
| | `--input-text-background-color-disabled` | `var(--rp-surface)` | 禁用背景 |
| | `--input-text-color-disabled` | `var(--rp-muted)` | 禁用文字 |
| | `--input-text-border-color-disabled` | `var(--rp-highlight-low)` | 禁用边框 |
| **Separators** | `--tabs-navbar-separator-color` | `var(--rp-highlight-low)` | 标签/导航分隔 |
| | `--chrome-content-separator-color` | `var(--rp-highlight-low)` | Chrome/内容分隔 |
| **Badges** | `--short-notification-background` | `var(--rp-rose)` | 通知徽章渐变起始 |
| | `--short-notification-gradient` | `var(--rp-iris)` | 通知徽章渐变终止 |
| | `--warning-icon-bgcolor` | `var(--rp-gold)` | 警告图标 |

### 直接选择器覆盖

| 选择器 | 覆盖值 | 原因 |
|--------|--------|------|
| `.urlbar-background` / `.urlbar-input-box` / `.urlbar-input` | `var(--rp-overlay)` | FF151 class 替代 #urlbar-background |
| `#urlbar[breakout-extend] .urlbar-background` | `var(--rp-overlay)` | 聚焦展开防止回退白色 |
| `.tabbrowser-tab[selected] .tab-background` | `border-bottom: 2px solid var(--rp-rose)` | Proton 选中标签指示线 |
| `tooltip` | `-moz-default-appearance: none` + overlay/text/highlight-med | 禁用 GTK 原生外观 |
| `#tab-preview-panel` | panel/text/border 变量 + overlay/text/subtle | Tab 悬浮预览面板 |
| `#tab-note-preview-panel` | `--tab-note-text-background/border-color` | Tab Note 预览 |
| `panel` / `panelview` / `menupopup` | panel 变量 + background/color | 分离 DOM 子树不继承 :root |
| `#urlbar-results` / `#PopupSearchAutoComplete` | panel 变量 + background | 下拉面板外框 |
| `.urlbarView-row` | base/text | 结果行内层 |
| `.search-one-offs` | base/highlight-low | 搜索引擎按钮区域 |
| `.autocomplete-richlistitem[selected]` | highlight-low/text | 搜索栏补全选中 |
| `menubar > menu[_moz-menuactive]` | highlight-med/text | 菜单 hover |
| `findbar .findbar-textbox` | overlay/text/highlight-med/rose | 查找栏输入框 |
| `#statuspanel` / `#statuspanel-label` | surface/subtle | 链接悬停预览 |
| `#sidebar-box scrollbar` | `scrollbar-color` | 侧边栏滚动条 |
| `:root:-moz-window-inactive *` | surface/muted/subtle | 非活跃窗口 |

## userContent.css — about: 页面变量映射

### 设计令牌覆盖（`@-moz-document url-prefix("about:")`）

| 分类 | Firefox 变量 | 覆盖值 |
|------|-------------|--------|
| **Canvas** | `--background-color-canvas` | `var(--rp-base)` |
| **Box** | `--background-color-box` | `var(--rp-surface)` |
| **Status** | `--background-color-information/success/warning` | `var(--rp-highlight-low)` |
| | `--background-color-critical` | `var(--rp-overlay)` |
| **Border** | `--border-color` | `var(--rp-highlight-med)` |
| | `--border-color-deemphasized` | `var(--rp-highlight-low)` |
| | `--border-color-interactive` | `var(--rp-highlight-med)` |
| **Accent** | `--color-accent-primary/hover/active/selected` | `var(--rp-rose)` |
| **Buttons** | `--button-background-color` | `var(--rp-overlay)` |
| | `--button-background-color-hover` | `var(--rp-highlight-low)` |
| | `--button-background-color-active` | `var(--rp-highlight-med)` |
| | `--button-text-color` | `var(--rp-text)` |
| | `--button-text-color-primary` | `var(--rp-base)` |
| | `--button-background-color-primary/hover/active` | `var(--rp-rose)` |
| | `--button-background-color-destructive/hover/active` | `var(--rp-love)` |
| | `--button-text-color-destructive` | `var(--rp-base)` |
| **Focus** | `--focus-outline-color` | `var(--rp-rose)` |
| **Icons** | `--icon-color` | `var(--rp-subtle)` |
| **Links** | `--link-color/hover/active/visited` | `var(--rp-iris)` |
| **Text** | `--text-color` | `var(--rp-text)` |
| | `--text-color-deemphasized` | `var(--rp-subtle)` |
| | `--text-color-disabled` | `var(--rp-muted)` |
| | `--text-color-error` | `var(--rp-love)` |
| **Toggle** | `--toggle-background-color` | `var(--rp-overlay)` |
| | `--toggle-background-color-hover` | `var(--rp-highlight-low)` |
| | `--toggle-background-color-active` | `var(--rp-highlight-med)` |
| | `--toggle-background-color-pressed/hover/active` | `var(--rp-rose)` |
| | `--toggle-border-color/hover/active` | `var(--rp-highlight-med)` |
| | `--toggle-dot-background-color` | `var(--rp-highlight-med)` |
| | `--toggle-dot-background-color-on-pressed` | `var(--rp-base)` |
| **Table** | `--table-row-background-color-alternate` | `var(--rp-surface)` |
| **Input (legacy)** | `--input-color/bgcolor/border-color` | text/overlay/highlight-med |
| **Input (new)** | `--input-text-background-color` | `var(--rp-overlay)` |
| | `--input-text-color` | `var(--rp-text)` |
| | `--input-text-border-color` | `var(--rp-highlight-med)` |
| | `--input-text-border` | `var(--border-width) solid var(--rp-highlight-med)` |
| | `--input-text-*-disabled` | surface/muted/highlight-low |

### New Tab 页面变量（`about:newtab` / `about:home`）

| 分类 | 变量 | 覆盖值 |
|------|------|--------|
| **背景** | `--newtab-background-color` | `var(--rp-base)` |
| | `--newtab-background-color-secondary` | `var(--rp-surface)` |
| | `--newtab-background-card` | `var(--rp-surface)` |
| **文字** | `--newtab-text-primary-color` | `var(--rp-text)` |
| | `--newtab-text-secondary-color` | `var(--rp-subtle)` |
| | `--newtab-text-secondary-text` | `var(--rp-subtle)` |
| | `--newtab-contextual-text-primary-color` | `var(--rp-text)` |
| | `--newtab-contextual-text-secondary-color` | `var(--rp-subtle)` |
| **交互** | `--newtab-element-hover-color` | `var(--rp-highlight-low)` |
| | `--newtab-element-active-color` | `var(--rp-highlight-med)` |
| | `--newtab-element-secondary-color` | `var(--rp-highlight-low)` |
| | `--newtab-element-secondary-hover-color` | `var(--rp-highlight-med)` |
| | `--newtab-element-secondary-active-color` | `var(--rp-highlight-high)` |
| **按钮** | `--newtab-button-background` | `var(--rp-overlay)` |
| | `--newtab-button-hover-background` | `var(--rp-highlight-low)` |
| | `--newtab-button-active-background` | `var(--rp-highlight-med)` |
| | `--newtab-button-text` | `var(--rp-text)` |
| **主操作** | `--newtab-primary-action-background` | `var(--rp-rose)` |
| | `--newtab-primary-action-background-dimmed` | `var(--rp-highlight-med)` |
| | `--newtab-primary-element-hover/active-color` | `var(--rp-rose)` |
| | `--newtab-primary-element-text-color` | `var(--rp-base)` |
| **卡片** | `--newtab-card-placeholder-background-color` | `var(--rp-highlight-low)` |
| | `--newtab-section-card-box-shadow-color` | `var(--rp-highlight-low)` |
| | `--newtab-inner-box-shadow-color` | `var(--rp-highlight-low)` |
| **状态** | `--newtab-status-success` | `var(--rp-foam)` |
| | `--newtab-status-error` | `var(--rp-love)` |
| **其他** | `--newtab-overlay-color` | `var(--rp-overlay)` |
| | `--newtab-wordmark-color` | `var(--rp-subtle)` |

### Firefox View 变量（`about:firefoxview`）

| 分类 | 变量 | 覆盖值 |
|------|------|--------|
| **页面** | `--fxview-background-color` | `var(--rp-base)` |
| | `--fxview-background-color-secondary` | `var(--rp-surface)` |
| | `--fxview-border` | `var(--rp-highlight-low)` |
| **文字** | `--fxview-text-primary-color` | `var(--rp-text)` |
| | `--fxview-text-secondary-color` | `var(--rp-subtle)` |
| | `--fxview-text-color-hover` | `var(--rp-text)` |
| **交互** | `--fxview-element-background-hover` | `var(--rp-highlight-low)` |
| | `--fxview-element-background-active` | `var(--rp-highlight-med)` |
| **主操作** | `--fxview-primary-action-background` | `var(--rp-iris)` |
| **指示器** | `--fxview-indicator-stroke-color-hover` | `var(--rp-highlight-med)` |

## 源码验证

所有 162 个非 `--rp-*` CSS 自定义属性均已在 Firefox 151 源码中验证存在。

关键定义文件：
- `toolkit/themes/shared/design-system/dist/tokens-shared.css` — 设计系统核心
- `toolkit/themes/shared/design-system/dist/tokens-brand.css` — 品牌层
- `browser/themes/shared/browser-colors.css` — 浏览器层
- `browser/themes/shared/urlbar/urlbar.tokens.css` — URL 栏
- `browser/themes/shared/urlbar/urlbarview.tokens.css` — URL 栏视图
- `browser/themes/shared/tabbrowser/tab.tokens.css` — 标签
- `browser/themes/shared/tabbrowser/tab-hover-preview.css` — 标签预览
- `toolkit/content/widgets/moz-toggle/moz-toggle.tokens.css` — 开关组件
- `browser/extensions/newtab/content-src/styles/_theme.scss` — 新标签页
- `browser/components/firefoxview/firefoxview.css` — Firefox View
