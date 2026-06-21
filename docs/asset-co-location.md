# 非 Nix 资产就近放置

## 规则

非 .nix 文件（模板、补丁、脚本、图标）放在消费它的 .nix 文件旁边。

- 1 个文件 → 同目录（如 `darkman.nix` + `darkman.svg`）
- 2+ 个文件 → 同名子目录（如 `firefox.nix` + `firefox/`）
- `secrets/` 保持集中（agenix 要求）

## 决策

| 变更前 | 变更后 |
|--------|--------|
| `config/` 混放多模块资产 | 每个模块拥有自己的资产 |
| `bat.nix` 引用 `../desktop/config/` | `bat.nix` 引用 `./rose-pine-bat.tmTheme` |
| `filemanager.nix` 引用 `./config/rose-pine-yazi-*` | `filemanager.nix` 引用 `./filemanager/rose-pine-yazi-*` |
| 文件名重复模块前缀（`rose-pine-firefox-userChrome.css`） | 目录提供上下文（`firefox/userChrome.css`） |

- **就近放置优于集中堆放** — 消除跨模块 `../` 引用，每个模块自包含
- **目录即命名空间** — 文件名更短，上下文由目录提供
- **secrets/ 例外** — agenix 的 `secrets.nix` 需要集中映射公钥到文件，就近放置会破坏此机制
