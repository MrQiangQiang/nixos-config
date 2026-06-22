{ ... }:
let
  keys = import ../secrets/keys.nix;
in
{
  # ── Primary user (SSOT) ───────────────────────────────────
  # 所有主机共享的 fugui 用户基础配置。
  # per-host 差异(如 homeMode)在各 host 的 default.nix 中追加,
  # 由 NixOS module 系统自动合并。
  users.users.fugui = {
    isNormalUser = true;
    linger = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    openssh.authorizedKeys.keys = [
      keys.users.fugui-github
      keys.users.fugui
      keys.users.fugui-desktop
    ];
  };
}
