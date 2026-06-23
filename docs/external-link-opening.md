# 外部链接打开

## 链路

Electron 应用 → `xdg-open` → `gio open` → `firefox.desktop`

## 决策

| 决策 | 为什么 |
|------|--------|
| 系统级装 `xdg-utils`（desktop.nix） | Electron `shell.openExternal()` 调 `xdg-open`，不调 portal（源码验证）。xdg-open 不在 PATH 则链接静默失败 |
| 默认浏览器声明在 firefox.nix | 同位原则：装 firefox 处声明其为默认，与 filemanager.nix 对 thunar/zathura 一致 |
| 不走 portal OpenURI | Electron 仅对 ShowItemInFolder 用 portal；OpenExternal 仍走 xdg-open（2026 主干源码确认） |

## trae-cn 例外

trae-cn 用 `buildFHSEnv`，`xdg-utils` 在 `targetPkgs`（沙箱自带 xdg-open）。Obsidian 用 `makeWrapper` 跑在宿主原生环境，依赖系统 PATH——这正是断链原因。
