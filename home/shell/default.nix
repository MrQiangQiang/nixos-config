{
  pkgs,
  config,
  lib,
  osConfig,
  ...
}:

let
  keys = import ../../secrets/keys.nix;
  # 每台主机用自己的 SSH 密钥签名（ssh-agent 只有本机密钥）
  # 加新主机时在 keys.nix 的 signingKeys 添加映射即可
  signingSshPublicKey = keys.signingKeys.${osConfig.networking.hostName};
  # allowed_signers 包含所有主机密钥（验证签名时需要）
  allSigningKeys = builtins.attrValues keys.signingKeys;
in
{
  imports = [
    ./bash.nix
    ./starship.nix
    ./fish.nix
    ./bat.nix
    ./helix.nix
    ./passage.nix
  ];

  systemd.user.services.ssh-add-key = {
    Unit = {
      Description = "Add SSH key to agent";
      After = [ "ssh-agent.service" ];
      Requires = [ "ssh-agent.service" ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      Type = "oneshot";
      Environment = "SSH_AUTH_SOCK=%t/ssh-agent";
      ExecStart = "${pkgs.openssh}/bin/ssh-add ${config.home.homeDirectory}/.ssh/id_ed25519";
    };
  };

  # SSH config 用 home.activation 直接写入文件，而非 home-manager 默认的 nix store 软链接。
  # 软链接属主为 nobody，SSH 9.x+ 会因 Bad owner 拒绝读取。
  home.activation.writeSshConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$HOME/.ssh"
    $DRY_RUN_CMD cp -f ${pkgs.writeText "ssh-config" ''
      Host *
        IdentitiesOnly yes
        AddKeysToAgent yes
      Host github.com
        HostName ssh.github.com
        Port 443
        User git
        IdentityFile ~/.ssh/id_ed25519
      Host gitlab.com
        HostName gitlab.com
        User git
        IdentityFile ~/.ssh/id_ed25519
      Host codeberg.org
        HostName codeberg.org
        User git
        IdentityFile ~/.ssh/id_ed25519
    ''} "$HOME/.ssh/config"
    $DRY_RUN_CMD chmod 600 "$HOME/.ssh/config"
  '';

  programs.git = {
    enable = true;
    signing = {
      key = signingSshPublicKey;
      signByDefault = true;
    };
    settings = {
      user = {
        name = "fugui";
        email = "chenzhiqiang0125@gmail.com";
      };
      # git 历史遗留命名：早期只支持 GPG 签名，2.34+ 增加 SSH 签名时保留了 `gpg.*` 命名空间。
      # 此处实际使用 SSH 签名（format = "ssh"），本地不使用 GPG。
      # 不可改名，见 https://git-scm.com/docs/git-config#Documentation/git-config.txt-gpgformat
      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
    };
  };

  home.file.".ssh/allowed_signers".text = ''
    chenzhiqiang0125@gmail.com ${lib.concatStringsSep "\n  chenzhiqiang0125@gmail.com " allSigningKeys}
  '';

  # 确保 SSH_AUTH_SOCK 在所有终端中可用（包括 IDE 集成终端）
  home.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent";

  programs.vim = {
    enable = true;
    extraConfig = ''
      set number
      syntax on
    '';
  };

  home.packages = with pkgs; [
    fastfetch
    htop
    jq
  ];
}
