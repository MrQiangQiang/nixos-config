{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.ssh = {
    startAgent = true;
    knownHosts = {
      "github.com" = {
        hostNames = [ "[ssh.github.com]:443" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
      };
      "gitlab.com" = {
        hostNames = [ "gitlab.com" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf";
      };
      "codeberg.org" = {
        hostNames = [ "codeberg.org" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIVIC02vnjFyL+I4RHfvIGNtOgJMe769VTF1VR4EB3ZB";
      };
    };
  };

  services.openssh = {
    enable = true;
    listenAddresses = [
      {
        addr = "0.0.0.0";
        port = 22;
      }
    ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      # mkDefault 允许需要远程部署的主机覆盖为 "prohibit-password"(仅密钥登录)
      PermitRootLogin = lib.mkDefault "no";
    };
  };
}
