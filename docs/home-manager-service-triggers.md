# Home Manager Service Triggers

## 核心决策

home-manager 管理的 systemd user service,如果服务运行时读取外部配置文件,必须用 `X-Reload-Triggers` 或 `X-Restart-Triggers` 让 sd-switch 在 `nixos-rebuild switch` 后自动 reload/restart 服务。

## 判断标准

- 有 `ExecReload` → `X-Reload-Triggers` (零中断,保持 D-Bus 注册和连接)
- 无 `ExecReload` → `X-Restart-Triggers` (restart)

## 根本原因

`nixos-rebuild switch` 触发 home-manager activation → sd-switch 比较新旧 `.service` 文件内容。服务通过固定路径(symlink 或 `%h/...`)读取配置文件,配置文件内容变化不会改变 `.service` 文件,sd-switch 检测不到变化,不会 reload/restart 服务。Triggers 将配置文件的 store path 嵌入 `.service` 文件,store path 变化时 `.service` 文件内容变化,sd-switch 触发 reload/restart。
