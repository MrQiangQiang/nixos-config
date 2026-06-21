# architecture

Multi-machine NixOS configuration. Two hosts (`laptop-1`, `desktop-1`), single flake.lock.

## Three layers

```
git        → code + text data (nixos-config, projects, knowledge, passwords)
git-annex  → large files (photos, videos, music)
Tailscale  → network (mesh VPN, MagicDNS)
```

## Naming

`[type]-[index]` — RFC 1178 safe. User `fugui` across all hosts.

| Host | Kernel | Role |
|------|--------|------|
| laptop-1 | default (6.x LTS) | daily driver, AI management |
| desktop-1 | latest (7.x) | heavy compute, Ollama, always-on data center |

## Topology

```
desktop-1 (source of truth, 7x24) ─── Tailscale ─── laptop-1 (consumer)
    │  ~/nixos-config (git)                           │  ~/nixos-config (git clone)
    │  ~/knowledge (git, qmd master)                  │  ~/knowledge (git clone)
    │  /data/annex (git-annex on HDD, backup)          │  ~/annex (git clone, manual)
    │  ~/.passage (git, age encrypted)                │  ~/.passage (git clone)
```

## Tool selection

| Tool | Why | Rejected alternative |
|------|-----|---------------------|
| Tailscale | Zero-config WireGuard mesh, MagicDNS | NetBird (less NixOS integration) |
| git | Version history, conflict resolution, review workflow | Syncthing (mixing git+syncthing is anti-pattern) |
| git-annex | Partial checkout, content-addressed, drop frees space | git-lfs (cannot drop files) |
| flake-parts | Community standard, perSystem | flake-utils (less opinionated) |
| agenix | Minimal, 2-host optimal | sops-nix (heavier) |
| nixos-rebuild | Built-in, zero deps | deploy-rs, colmena (overkill for 2 hosts) |

## Module organization

```
hosts/default.nix  → mkHost (shared defaults: locale, boot, nix settings)
hosts/<name>/      → host-specific (kernel, GPU, services, user)
modules/           → cross-host (tailscale, proxy, ssh, system)
home/              → user environment (shell, desktop, dev tools, agents)
lib/mkHost.nix     → host constructor (single source for defaults)
```

## Secrets

`secrets/keys.nix` = single source of truth for all SSH public keys. `secrets/secrets.nix` declares which key encrypts which age file. `agenix -r` rekeys when adding a host.

## Remote deploy

```
nixos-rebuild switch --flake .#desktop-1 --target-host fugui@desktop-1.tail0f7af0.ts.net
```

Builds on laptop-1, deploys to desktop-1 via Tailscale. No deploy-rs needed; two-host scale is trivial.
