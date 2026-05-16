{
  config
  lib,
  pkg,
  ...
}:

{
  home.packages = with pkgs; [ foot ];
}
