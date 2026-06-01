{ pkgs, ... }:

let
  nixosSshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJvALtc74c420xWoDLT6mwGO/Mf7JemicsoeFjFo87Ez fugui@nixos";
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        identitiesOnly = true;
        addKeysToAgent = "yes";
      };
      "github.com" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
      };
      "gitlab.com" = {
        hostname = "gitlab.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
      };
      "codeberg.org" = {
        hostname = "codeberg.org";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  programs.git = {
    enable = true;
    userName = "fugui";
    userEmail = "chenzhiqiang0125@gmail.com";
    signing = {
      key = nixosSshPublicKey;
      signByDefault = true;
    };
    extraConfig = {
      gpg = {
        format = "ssh";
      };
      gpg.ssh = {
        allowedSignersFile = "~/.ssh/allowed_signers";
      };
      tag = {
        gpgsign = true;
      };
    };
  };

  home.file.".ssh/allowed_signers".text = ''
    chenzhiqiang0125@gmail.com ${nixosSshPublicKey}
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
