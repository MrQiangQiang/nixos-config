{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  palette = import ./desktop/palette.nix { inherit osConfig; };
  keybinds = import ./desktop/keybind-registry.nix { inherit lib; };
in
{
  imports = [
    ./agents
    ./desktop
    ./dev
    ./repos.nix
    ./shell
  ];

  _module.args.palette = palette;
  _module.args.keybinds = keybinds;

  custom.trae-cn.enable = true;
}
