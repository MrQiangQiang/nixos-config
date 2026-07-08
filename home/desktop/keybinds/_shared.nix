{ lib }:

let
  # Intra-app conflict detection: same app + same key+mods+mode = build error
  # Note: same key+mods with different modes is intentional (e.g., kwm passthrough)
  checkConflicts =
    appName: bindings:
    let
      keyId = b: "${lib.concatStringsSep "+" b.mods}+${b.key}@${b.mode or "default"}";
      ids = lib.imap0 (i: b: {
        inherit i;
        id = keyId b;
        inherit (b) desc;
      }) bindings;
      findDup = lib.concatMap (a: lib.filter (b: a.i < b.i && a.id == b.id) ids) ids;
      dupDescs = map (d: "${d.id} → ${d.desc}") findDup;
    in
    assert lib.assertMsg (
      findDup == [ ]
    ) "keybind-registry: ${appName} has conflicting bindings: ${lib.concatStringsSep "; " dupDescs}";
    bindings;
in
{
  inherit checkConflicts;
}
