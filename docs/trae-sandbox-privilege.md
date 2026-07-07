# Trae Sandbox 特权提升

> Trae IDE 终端在 buildFHSEnv/bubblewrap sandbox 中继承 NoNewPrivs,无法使用 sudo,改用 run0 实现特权提升

---

## 根本原因

Trae IDE 的 `buildFHSEnv` 内部调用 `bubblewrap`,bubblewrap 硬编码 `PR_SET_NO_NEW_PRIVS`。该内核标志**不可逆**,阻止所有 SUID 执行 → `sudo`(依赖 SUID)不可用。

TTY/普通终端无 NoNewPrivs,sudo 正常可用,无需 run0。

---

## 方案

`run0`(systemd 256+)是 sudo 的现代替代,**不依赖 SUID**:

```
run0 → D-Bus → systemd(PID 1) StartTransientUnit → polkitd 认证 → PAM(systemd-run0) → 特权 service
```

run0 通过 D-Bus 请求 systemd 启动 transient service,认证由 polkit 完成,完全绕过 SUID。Arch man page 明确:run0 专为 "NoNewPrivileges= 环境下 SetUID/SetGID 不可用" 设计。

---

## 为什么需要两处修改

| 修改 | 解决的问题 | 位置 |
|------|-----------|------|
| `security.pam.services.systemd-run0 = {};` | run0 通过 "systemd-run0" PAM 栈认证,默认无此服务 → nixpkgs issue #361592(认证后 PAM session 设置失败) | `modules/desktop.nix` |
| `extraBwrapArgs = ["--ro-bind" "/etc/pam.d" "/etc/pam.d"];` | buildFHSEnv 默认用 shadow 包的 pam.d(9 文件)遮蔽宿主机 pam.d(23 文件),run0 找不到 PAM 配置 | `packages/trae-cn.nix` |

### 空属性集的含义

`{}` = `useDefaultRules = true`,创建与 sudo 等效的默认 PAM 服务,无需额外配置。

### extraBwrapArgs 为什么用宿主机路径

`extraBwrapArgs` 在 bwrap 命令中执行,bwrap 解析源路径时基于**宿主机文件系统**。`/.host-etc` 只存在于 sandbox 内部(由 buildFHSEnv 通过 `--ro-bind /etc /.host-etc` 创建),bwrap 看不到。源路径必须用 `/etc/pam.d`。

---

## 为什么放 desktop.nix 而非 security.nix

- **run0 是桌面场景专属**:Trae IDE 是桌面应用,TTY 用 sudo
- **`security.nix` 命名太宽泛**:未来会混入无关配置,违反职责单一
- **desktop.nix 已有 polkit.enable**:polkit 是 run0 的认证依赖,内聚

---

## 认证流程

```
Trae IDE 终端(run0)
    ↓
polkit-gnome agent(home/desktop/polkit.nix)→ GUI 密码框
    ↓
auth_admin_keep 缓存 → 一段时间内免重输
```

TTY 环境下 run0 使用 pkttyagent(文本输入),但 TTY 无 NoNewPrivs,直接用 sudo 即可。

---

## 设计原则

| 原则 | 验证 |
|------|------|
| **简单** | 共 2 行配置 + 注释,无新文件,无新模块 |
| **职责单一** | desktop.nix 管 PAM 服务(系统层),trae-cn.nix 管 FHS 环境(package 层) |
| **唯一来源** | PAM 服务定义在系统层,FHS 环境只暴露不复制 |
| **低复杂度** | 利用 NixOS 声明式 PAM + buildFHSEnv 官方接口,无 patch/hack |
| **高内聚低耦合** | polkit + PAM 服务同文件;FHS 环境配置在 package 层 |
| **多主机** | desktop.nix 通过 `custom.desktop.enable` 选项,所有桌面主机自动生效 |
| **成熟新技术** | run0(systemd 256+,2024-06),2026 年已成熟 |
