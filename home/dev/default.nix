{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    trae-cn
  ];
}
