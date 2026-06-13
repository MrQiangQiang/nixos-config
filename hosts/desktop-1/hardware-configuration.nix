# Placeholder — replace with the output of:
#   nixos-generate-config --root /
# on the target machine after bootstrap install.

{ ... }:
{
  fileSystems."/" = {
    device = "PLACEHOLDER";
    fsType = "btrfs";
  };
}
