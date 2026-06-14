{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.syncthing = {
    enable = true;
    user = "fugui";
    dataDir = "/home/fugui/syncthing";
    openDefaultPorts = true;
    settings = {
      devices = { };
      folders = { };
    };
  };
}
