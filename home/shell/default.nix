{ pkgs, config, lib, ... }:

let
  keys = import ../../secrets/keys.nix;
  signingSshPublicKey = keys.users.fugui;
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
      gpg = {
        format = "ssh";
      };
      gpg.ssh = {
        allowedSignersFile = "~/.ssh/allowed_signers";
      };
    };
  };

  home.file.".ssh/allowed_signers".text = ''
    chenzhiqiang0125@gmail.com ${signingSshPublicKey}
  '';

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
