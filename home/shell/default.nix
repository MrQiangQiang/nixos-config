{ pkgs, config, ... }:

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

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        IdentitiesOnly = true;
        AddKeysToAgent = "yes";
      };
      "github.com" = {
        HostName = "ssh.github.com";
        Port = 443;
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
      };
      "gitlab.com" = {
        HostName = "gitlab.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
      };
      "codeberg.org" = {
        HostName = "codeberg.org";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
      };
    };
  };

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
