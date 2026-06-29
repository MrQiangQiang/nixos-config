# AGENTS.md

NixOS flake 多主机声明式配置。

## 禁止

- 手动编辑 `~/.config` — 所有配置由 home-manager 管理
- `cp + rm` 大文件 — 用 `git annex`
- 在 `home/dev/` 重复定义 `home/agents/` 已有的共享内容

## Lock 文件

- **仅 desktop-1** 运行 `nix flake update`，commit + push
- **laptop-1** 只 `git pull`；误 update 后 `git restore flake.lock && git pull`
- 禁止手动编辑 `flake.lock`
- 详见 `docs/multi-machine.md`

## 安全边界

直接执行：
- `nix flake check`、`nix build`、`nixfmt`
- `home-manager switch`

必须询问：
- `sudo nixos-rebuild switch`
- `nix flake update`
- 编辑 `secrets/` 或 agenix rekey
- `disko` 分区操作
