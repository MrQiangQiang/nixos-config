{ pkgs, ... }:

{
  # ── Bitwarden CLI (rbw) ──────────────────────────────────
  # rbw: Rust 重写的非官方 Bitwarden CLI，Home Manager 原生模块
  #   - 有状态：rbw-agent 系统服务自动管理登录/解锁
  #   - 无需手动传递 BW_SESSION 环境变量
  #   - 声明式管理 ~/.config/rbw/config.json
  #   - 用途：管理 Secure Notes（恢复密钥、Token、部署密钥等）
  #
  # 不需要浏览器扩展：本场景仅需 CLI 读写 Secure Notes，
  # 无需网页自动填充。扩展由浏览器商店分发，不在此管理。

  programs.rbw = {
    enable = true;
    settings = {
      email = "chenzhiqiang0125@gmail.com";
      lock_timeout = 43200; # 12 小时（秒）
      pinentry = pkgs.pinentry-tty;
    };
  };
}
