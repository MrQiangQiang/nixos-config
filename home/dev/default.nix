{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./distrobox.nix ];

  home.packages = with pkgs; [
    trae-cn
  ];
}
