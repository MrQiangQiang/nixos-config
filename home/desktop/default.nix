{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

{
  imports = [
    ./river.nix
    ./kwm.nix
    ./waybar.nix
    ./swaybg.nix
    ./foot.nix
    ./firefox.nix
  ];
}
