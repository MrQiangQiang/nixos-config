# AGENTS.md — nixos-config

NixOS flake 配置仓库，多主机（desktop-1, laptop-1）声明式管理。

## Build & Test

```bash
# 切换主机配置
sudo nixos-rebuild switch --flake .#desktop-1

# 切换用户配置
home-manager switch --flake .#fugui@desktop-1

# 验证 flake
nix flake check

# 更新 flake lock
nix flake update
```

## Architecture

- `flake.nix` — inputs + outputs（flake-parts）
- `hosts/` — 每主机配置（desktop-1, laptop-1）
- `home/` — home-manager 用户配置
  - `agents/` — AI agent 共享配置 SSOT（MCP, commands, skills, rules）
  - `dev/` — 各 AI 工具消费者（opencode, trae-cn, codex, claude-code）
- `modules/` — NixOS 系统模块（ollama, tailscale, desktop 等）
- `packages/` — 自定义派生 + overlay（版本覆盖在此）
- `secrets/` — agenix 加密密钥

## Critical Rules

- **禁止**直接编辑 `~/.config`——改 `.nix` 文件后 `home-manager switch`
- **禁止**直接编辑 `hardware-configuration.nix`——用 disko 或手动 nixos-generate-config
- **禁止**手动改 `flake.lock`——用 `nix flake update`
- **禁止** `cp + rm` 大文件——用 `git annex`
- `home/agents/` 是 AI 配置 SSOT——不要在 `home/dev/` 重复定义共享内容

## Safety & Permissions

**Allowed without prompt:**
- `nix flake check`、`nix build`、`nixfmt` 单文件
- `home-manager switch`（用户级，可逆）

**Ask first:**
- `sudo nixos-rebuild switch`（系统级，影响登录会话）
- `nix flake update`（改变 lock，影响可复现性）
- 编辑 `secrets/` 或 `agenix` rekey
- `disko` 分区操作

## Deep Context

详见 `docs/ai-agent-architecture.md`（AI agent 架构决策记录）。
