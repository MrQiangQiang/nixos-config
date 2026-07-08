{ lib }:

let
  checkConflicts = (import ./_shared.nix { inherit lib; }).checkConflicts;
in
{
  conventions = import ./conventions.nix { inherit lib checkConflicts; };
  kwm = import ./kwm.nix { inherit lib checkConflicts; };
  firefox = import ./firefox.nix { inherit lib checkConflicts; };
  foot = import ./foot.nix { inherit lib checkConflicts; };
  fuzzel = import ./fuzzel.nix { inherit lib checkConflicts; };
  fcitx5 = import ./fcitx5.nix { inherit lib checkConflicts; };
  trae-cn = import ./trae-cn.nix { inherit lib checkConflicts; };
  opencode = import ./opencode.nix { inherit lib checkConflicts; };
  yazi = import ./yazi.nix { inherit lib checkConflicts; };
  helix = import ./helix.nix { inherit lib checkConflicts; };
  vim = import ./vim.nix { inherit lib checkConflicts; };
}
