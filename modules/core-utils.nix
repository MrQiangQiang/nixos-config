{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    curl
    tree
    wget
  ];

  # root 执行 nixos-rebuild 时访问 fugui 拥有的 git 仓库,libgit2 报 dubious ownership。
  # /etc/gitconfig 系统级生效(含 root),声明后 AGENTS.md 部署命令无需手动 workaround。
  environment.etc.gitconfig.text = ''
    [safe]
      directory = /home/fugui/nixos-config
  '';
}
