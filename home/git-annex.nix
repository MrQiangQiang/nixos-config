# git-annex 元数据定期同步 (user service)
#
# Joey Hess 官方推荐 user service (git-annex.branchable.com/tips/Systemd_unit);
# linger 已在 modules/users.nix 启用,timer 在用户未登录时仍可运行。
#
# 仅非 desktop-1 主机: 主动 push 自己的 git-annex 分支到 desktop-1
# + fetch desktop-1 的新增元数据。desktop-1 是 canonical,无需主动 sync。
#
# 迁移自 system service: 消除 polkit 认证依赖
# (systemctl start 系统服务需要 auth_admin_keep,非交互环境会超时)。
{
  pkgs,
  lib,
  osConfig,
  ...
}:

let
  syncScript = pkgs.writeShellScript "git-annex-sync" ''
    export PATH="${
      lib.makeBinPath [
        pkgs.git
        pkgs.git-annex
        pkgs.openssh
      ]
    }"
    if [ -d "$HOME/annex/.git" ]; then
      cd "$HOME/annex"
      git annex sync --no-content
    fi
  '';
in
{
  systemd.user.services.git-annex-sync = lib.mkIf (osConfig.networking.hostName != "desktop-1") {
    Unit = {
      Description = "Sync git-annex metadata with desktop-1";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${syncScript}";
    };
  };

  systemd.user.timers.git-annex-sync = lib.mkIf (osConfig.networking.hostName != "desktop-1") {
    Unit = {
      Description = "Hourly git-annex metadata sync with desktop-1";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
    Timer = {
      OnCalendar = "hourly";
      Persistent = true;
      RandomizedDelaySec = "5min";
    };
  };
}
