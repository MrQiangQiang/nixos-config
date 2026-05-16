{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./desktop
    ./dev
    ./shell
  ];
  home.stateVersion = "25.11";
}
