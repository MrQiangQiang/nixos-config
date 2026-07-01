{ pkgs, lib, config, ... }:
{
  environment.systemPackages = [ pkgs.git-annex ];

  # 非 desktop-1 主机: 定期 sync 元数据 (client 主动模型, Joey Hess 官方推荐)
  # laptop-1 主动 push 自己的 git-annex 分支 (UUID + get/drop 元数据) 到 desktop-1
  # + 主动 fetch desktop-1 的新增文件元数据
  # desktop-1 无需此 timer: desktop-1 是 canonical, 无需主动 sync laptop-1 (没有 laptop-1 remote)
  systemd.services.git-annex-sync = lib.mkIf (config.networking.hostName != "desktop-1") {
    description = "Sync git-annex metadata with desktop-1";
    after = [ "network-online.target" "tailscaled.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "fugui";
      Group = "users";
    };
    path = [ pkgs.git pkgs.git-annex pkgs.openssh ];
    script = ''
      if [ -d "${config.users.users.fugui.home}/annex/.git" ]; then
        cd "${config.users.users.fugui.home}/annex" && git annex sync --no-content
      fi
    '';
  };

  systemd.timers.git-annex-sync = lib.mkIf (config.networking.hostName != "desktop-1") {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
      RandomizedDelaySec = "5min";
    };
  };
}
