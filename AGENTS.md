# AGENTS.md

## 禁止

- 编辑 `~/.config`(由 home-manager 管理)
- 大文件 `cp+rm`(用 `git annex`)
- 在 `home/dev/` 重复定义 `home/agents/` 已有的共享内容

## Lock 文件

- **仅 desktop-1** 运行 `nix flake update` 并 push
- **laptop-1** 只 `git pull`;误 update 后 `git restore flake.lock && git pull`

## 部署

编译在目标主机执行。无 `home-manager` CLI,用 `nixos-rebuild switch`。

远程部署(已 commit + push 后):

```bash
ssh <目标主机> 'cd ~/nixos-config && git pull && nixos-rebuild switch --flake .#<目标主机>'
```

## 必须询问

- `nix flake update`
- 编辑 `secrets/` 或 agenix rekey
- `disko` 分区操作
