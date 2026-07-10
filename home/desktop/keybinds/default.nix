{ lib }:

let
  checkConflicts = (import ./_shared.nix { inherit lib; }).checkConflicts;
in
{
  conventions = import ./conventions.nix { inherit checkConflicts; };
  kwm = import ./kwm.nix { inherit lib checkConflicts; };
  firefox = import ./firefox.nix { inherit checkConflicts; };
  foot = import ./foot.nix { inherit checkConflicts; };
  fuzzel = import ./fuzzel.nix { inherit checkConflicts; };
  fcitx5 = import ./fcitx5.nix { inherit checkConflicts; };
  trae-cn = import ./trae-cn.nix { inherit checkConflicts; };
  opencode = import ./opencode.nix { inherit checkConflicts; };
  yazi = import ./yazi.nix { inherit checkConflicts; };
  helix = import ./helix.nix { inherit checkConflicts; };
  vim = import ./vim.nix { inherit checkConflicts; };
}
