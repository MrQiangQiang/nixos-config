# deploy

## Path

```
Primary:   phone-hotspot+VPN → git clone → nix run .#disko → nixos-install --flake
Fallback:  USB Ventoy → bootstrap-config.nix → nixos-install → git clone → nixos-rebuild switch
```

## Decisions

| Decision | Rationale |
|----------|-----------|
| phone hotspot over clash USB | Zero setup. VPN on phone routes all traffic |
| `--no-filesystems` for nixos-generate-config | fileSystems come from disko; avoids mountpoint conflict |
| bootstrap as offline fallback | Minimal self-containtains config: SSH, NetworkManager, domestic mirrors, user |
| `--no-root-password` broken | nixos-install skips prompt only; `users.users.root.hashedPassword = ""` required |
| disko mountpoint collision | top-level `mountpoint = "/"` conflicts with `@` subvolume. Only subvolume should define mountpoint |

## Post-install

```
BIOS → EXPO 6000 → GPU bus IDs → agenix rekey → nixos-rebuild switch --flake
```
