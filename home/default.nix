{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  palette = import ./desktop/palette.nix { inherit osConfig; };
  keybinds = import ./desktop/keybinds { inherit lib; };
in
{
  imports = [
    ./agents
    ./desktop
    ./dev
    ./git-annex.nix
    ./repos.nix
    ./shell
  ];

  _module.args.palette = palette;
  _module.args.keybinds = keybinds;

  custom.trae-cn.enable = true;
}
