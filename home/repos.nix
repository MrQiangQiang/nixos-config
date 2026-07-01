# Personal repositories — declarative git clone on activation
#
# Architecture:
#   SSOT for all personal git repos cloned to the home directory.
#   Idempotent — skips if .git/ already exists on subsequent activations.
#   Runs after writeSshConfig so ~/.ssh/config is ready for git clone.
#   Failures are non-blocking — warns, retries next activation.
#
#   All hosts (desktop-1, laptop-1, ...) share the same repo list.
#   Paths are consistent across machines via config.home.homeDirectory.
#
#   Repo URLs are safe in public Nix config (SSH auth required for private repos).
#
# To add a new repo:
#   1. Append an entry to `repos` below
#   2. nixos-rebuild switch — auto-cloned on next activation
{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  home = config.home.homeDirectory;
  git = "${pkgs.git}/bin/git";
  gitAnnex = "${pkgs.git-annex}/bin/git-annex";
  ssh = "${pkgs.openssh}/bin/ssh";

  repos = [
    {
      name = "knowledge";
      url = "git@github.com:MrQiangQiang/knowledge.git";
      path = "${home}/knowledge";
    }
    {
      name = "secrets";
      url = "git@github.com:MrQiangQiang/secrets.git";
      path = "${home}/.passage/store";
    }
  ];
in
{
  home.activation.clonePersonalRepos = lib.hm.dag.entryAfter [ "writeSshConfig" ] (
    builtins.concatStringsSep "\n" (
      map (repo: ''
        if [ ! -d '${repo.path}/.git' ]; then
          if GIT_SSH_COMMAND='${ssh}' run ${git} clone '${repo.url}' '${repo.path}'; then
            :
          else
            echo "Warning: ${repo.name} clone failed, run manually:" >&2
            echo "  git clone ${repo.url} ${repo.path}" >&2
          fi
        fi
      '') repos
    )
  );

  # annex 仓库: clone (如果不存在) + init + group (仅第一次) + sync (每次)
  # 单独 activation 而非加入 repos 列表, 因为需要 postClone hook (git annex init)
  # git-annex 运行时需要 git 在 PATH 中
  # 仅非 desktop-1 主机执行: desktop-1 自身是 canonical 仓库 (/data/annex), 无需 clone 自己。
  # init description 用主机名 (osConfig.networking.hostName) 而非硬编码, 支持未来新增主机。
  # init/group 仅第一次 (实验验证非幂等, 每次产生 1 commit 垃圾); sync 幂等 (无变化零 commit)。
  home.activation.cloneAnnexRepo = lib.hm.dag.entryAfter [ "clonePersonalRepos" ] (
    lib.optionalString (osConfig.networking.hostName != "desktop-1") ''
      export PATH="${pkgs.git}/bin:${pkgs.git-annex}/bin:$PATH"
      if [ ! -d '${home}/annex/.git' ]; then
        if GIT_SSH_COMMAND='${ssh}' run ${git} clone 'fugui@desktop-1.tail0f7af0.ts.net:/data/annex' '${home}/annex'; then
          :
        else
          echo "Warning: annex clone failed, run manually:" >&2
          echo "  git clone fugui@desktop-1.tail0f7af0.ts.net:/data/annex ${home}/annex" >&2
        fi
      fi
      if [ -d '${home}/annex/.git' ]; then
        cd '${home}/annex'
        # init + group 仅第一次 (避免垃圾 commit)
        if ! git config --get annex.uuid >/dev/null 2>&1; then
          run ${gitAnnex} init '${osConfig.networking.hostName}' && run ${gitAnnex} group here manual || \
            echo "Warning: annex init/group failed, run manually:" >&2
        fi
        # sync 总是跑 (幂等, 上报 UUID + 拉取 desktop-1 新元数据)
        run ${gitAnnex} sync --no-content || \
          echo "Warning: annex sync failed, run manually: git annex sync --no-content" >&2
      fi
    ''
  );
}
