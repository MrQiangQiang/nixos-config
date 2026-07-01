# ripgrep — recursive search (ANSI auto-follows terminal palette, no theme config)
#
# 底层二进制实测只有两份（2026-07-02 sha256 验证）：
#   1. nixpkgs ripgrep-15.1.0 — 本配置安装到用户 PATH，被多消费方共享：
#        终端 shell / OpenCode(which rg) / Codex(系统 PATH)
#        Claude Code 包依赖同 derivation，但通过自己 wrapper 的 PATH 注入消费
#        （不经过此 PATH 入口，但底层是同一个 nix store 文件 — 非额外一份）
#   2. Trae bundled @vscode/ripgrep 15.0.0 — VS Code fork 自带，非 nix 管理，无法移除
#
# 本配置作用：把 nixpkgs ripgrep 加入用户 PATH（供终端/OpenCode/Codex 使用）。
# 删除后：Claude Code 不受影响（自带 wrapper PATH），Trae 不受影响（用 bundled），
#         但终端/OpenCode/Codex 会失去 rg → 触发 OpenCode 下载 bundled、Codex 报错。
{ programs.ripgrep.enable = true; }
