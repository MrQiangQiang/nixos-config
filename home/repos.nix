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
          if GIT_SSH_COMMAND='${ssh}' $DRY_RUN_CMD ${git} clone '${repo.url}' '${repo.path}'; then
            :
          else
            echo "Warning: ${repo.name} clone failed, run manually:" >&2
            echo "  git clone ${repo.url} ${repo.path}" >&2
          fi
        fi
      '') repos
    )
  );

  # annex 仓库: clone (如果不存在) + init + group (幂等, 每次 activation 都执行)
  # 单独 activation 而非加入 repos 列表, 因为需要 postClone hook (git annex init)
  home.activation.cloneAnnexRepo = lib.hm.dag.entryAfter [ "clonePersonalRepos" ] ''
    if [ ! -d '${home}/annex/.git' ]; then
      if GIT_SSH_COMMAND='${ssh}' $DRY_RUN_CMD ${git} clone 'fugui@desktop-1.tail0f7af0.ts.net:/data/annex' '${home}/annex'; then
        :
      else
        echo "Warning: annex clone failed, run manually:" >&2
        echo "  git clone fugui@desktop-1.tail0f7af0.ts.net:/data/annex ${home}/annex" >&2
      fi
    fi
    # init + group 幂等, 每次 activation 都执行 (确保 group 被设置)
    if [ -d '${home}/annex/.git' ]; then
      cd '${home}/annex' && $DRY_RUN_CMD ${gitAnnex} init laptop-1 && $DRY_RUN_CMD ${gitAnnex} group here manual || \
        echo "Warning: annex init/group failed, run manually:" >&2
    fi
  '';
}
