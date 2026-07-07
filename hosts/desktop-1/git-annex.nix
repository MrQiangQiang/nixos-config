# git-annex canonical 仓库:初始化 + GitHub 元数据备份
#
# 幂等初始化 /data/annex 为 canonical git-annex 仓库。
# 所有命令幂等(官方 man page 确认),安全重复执行。
# ExecStartPre 的 `+` 前缀以 root 运行 chown(nofail 挂载点 tmpfiles 时序不可靠,
# 改用 ExecStartPre+ 是 nixpkgs 实证模式,见 wgautomesh/unifi-os-server 模块)。
# RequiresMountsFor 不依赖 disko 生成的具体挂载单元名,更稳健。
#
# GitHub 备份:每天备份 git-annex + main 分支到 GitHub (元数据异地备份)
# annex-ignore=true 阻止 git-annex sync 走 GitHub, 但手动 git push 不受影响
{ pkgs, ... }:
{
  # ── git-annex canonical repo initialization ───────────────
  systemd.services.git-annex-init = {
    description = "Initialize git-annex canonical repo at /data/annex";
    wantedBy = [ "multi-user.target" ];
    unitConfig.RequiresMountsFor = "/data/annex";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "fugui";
      Group = "users";
      WorkingDirectory = "/data/annex";
      ExecStartPre = [ "+${pkgs.coreutils}/bin/chown fugui:users /data/annex" ];
    };
    path = [
      pkgs.git
      pkgs.git-annex
      pkgs.openssh
    ];
    script = ''
      [ -d .git ] || git init
      # init/group/required 仅第一次 (实验验证非幂等, 每次产生垃圾 commit)
      if ! git config --get annex.uuid >/dev/null 2>&1; then
        git annex init "desktop-1"
        git annex group here backup
        git annex required here "present"
      fi
      # numcopies/mincopies 是 git config, 幂等
      git annex numcopies 1
      git annex mincopies 1
      git remote get-url origin 2>/dev/null || \
        git remote add origin git@github.com:MrQiangQiang/annex.git
    '';
  };

  # ── git-annex GitHub backup ───────────────────────────────
  systemd.services.git-annex-backup-github = {
    description = "Backup git-annex metadata to GitHub";
    after = [
      "network-online.target"
      "git-annex-init.service"
    ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "fugui";
      Group = "users";
      WorkingDirectory = "/data/annex";
    };
    path = [
      pkgs.git
      pkgs.openssh
    ];
    script = "git push origin git-annex main";
  };

  systemd.timers.git-annex-backup-github = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30min";
    };
  };
}
