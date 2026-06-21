# network

## Architecture

```
┌─ mihomo TUN ────────────────────────────────────┐
│  auto-route + strict-route + dns-hijack          │
│  ⇒ all traffic through tun0 → rules → upstream   │
│  ⇒ single source of truth for routing            │
├─ systemd-resolved ───────────────────────────────┤
│  223.5.5.5, 119.29.29.29  (domestic DNS fallback)│
│  Tailscale injects MagicDNS via resolvectl API   │
├─ Tailscale ──────────────────────────────────────┤
│  WireGuard mesh: desktop-1 ↔ laptop-1            │
│  MagicDNS: <host>.tail0f7af0.ts.net              │
│  Serve: localhost:8181 → HTTPS tailnet (qmd MCP)  │
│  SSH via Tailscale IP (no port forwarding)        │
└──────────────────────────────────────────────────┘
```

## Decisions

| Decision | Rationale |
|----------|-----------|
| mihomo TUN mode | Network-layer routing. Eliminates per-app proxy config |
| No `http_proxy` env vars | Redundant with TUN. Caused nix-daemon deadlock when mihomo down |
| systemd-resolved | Tailscale Wiki recommends. `networking.nameservers` = fallback pool |
| Tailscale auth-state ephemeral | Re-auth after rebuild if service restarts |
| mihomo rules for Tailscale | `100.64.0.0/10` + port 41641 DIRECT; `tailscale.com`/`tailscale.io` via proxy |
| `nix.settings.substituters` | Domestic mirrors with cache.nixos.org fallback; priority-ordered |

## Remote deploy

```
nixos-rebuild switch --flake .#desktop-1 --target-host fugui@desktop-1.tail0f7af0.ts.net
```
