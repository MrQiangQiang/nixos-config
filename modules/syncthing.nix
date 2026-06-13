{ config, pkgs, lib, ... }:
{
  services.syncthing = {
    enable = true;
    user = "fugui";
    openDefaultPorts = true;
    settings = {
      devices = { };
      folders = { };
    };
  };
}
