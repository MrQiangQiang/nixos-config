# passage — age-encrypted personal secret store
#
# Architecture:
#   SSH ed25519 key → age identity (decrypt)
#   SSH ed25519 pub → age recipient (encrypt)
#   ~/.passage/store/*.age → git 同步跨机器(age 加密,安全推 GitHub)
#   .age-recipients → 列出所有机器的 SSH pubkey (Nix SSOT)
#   ~/.passage/store/ → auto-cloned from git@github.com:MrQiangQiang/secrets.git
#
# No daemon, no type system, no cloud dependency.
# One file = one secret. Filename = description.
{ config, lib, pkgs, ... }:

let
  keys = import ../../secrets/keys.nix;
in
{
  home.packages = [ pkgs.passage ];

  # Clone secrets repo on activation (idempotent, all machines).
  # Runs after writeSshConfig so ~/.ssh/config is in place.
  # On new machines without SSH key, clone fails gracefully — retries next activation.
  home.activation.ensureSecretsRepo = lib.hm.dag.entryAfter [ "writeSshConfig" ] ''
    if [ ! -d "$HOME/.passage/store/.git" ]; then
      if $DRY_RUN_CMD git clone git@github.com:MrQiangQiang/secrets.git "$HOME/.passage/store"; then
        :
      else
        echo "Warning: secrets repo clone failed, run manually later:" >&2
        echo "  git clone git@github.com:MrQiangQiang/secrets.git ~/.passage/store" >&2
      fi
    fi
  '';

  home.file.".passage/store/.age-recipients".text = ''
    ${keys.users.fugui-desktop}
    ${keys.users.fugui}
  '';

  home.activation.passageIdentities = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f "$HOME/.ssh/id_ed25519" ]; then
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$HOME/.passage"
      $DRY_RUN_CMD cp "$HOME/.ssh/id_ed25519" "$HOME/.passage/identities"
      $DRY_RUN_CMD chmod 600 "$HOME/.passage/identities"
    fi
  '';
}
