# storage

## Layout

```
nvme0n1 (Samsung 990 Pro 2 TiB)  GPT  disko
├── p1  512M  vfat   /boot/efi     ESP
├── p2  2G    ext4   /boot
└── p3  rest  btrfs  / (root)

6 btrfs subvolumes (all compress=zstd,noatime):
  @          /                     system root
  @home      /home                 user data
  @nix       /nix                  Nix store (snapshot-excluded)
  @var_cache /var/cache            package cache
  @var_log   /var/log              logs
  @ollama    /var/lib/ollama     LLM models (snapshot-excluded)

sda (HDD 1TB)  GPT  disko
└── p1  100%  btrfs  /data/annex   git-annex data repository (nofail, compress=zstd)
```

## Decisions

| Decision | Rationale |
|----------|-----------|
| btrfs, not ext4 | snapshots, compression, subvolumes share space |
| zstd compression | 20-40% space savings on code/text; negligible CPU cost |
| noatime | eliminates write amplification on reads |
| zramSwap, no disk swap | fail-fast for Ollama VRAM overflow. `systemd-oomd` kills before thrash |
| disko | declarative; pinned in flake.lock; generates `fileSystems` |
| `@nix` separate | keeps `/nix/store` out of root snapshots |
| `@ollama` separate | model data isolated; no snapshots |
| boot 2G | multiple kernel generations; safe margin over 512M minimum |
| HDD `nofail` | boot proceeds if HDD fails; git-annex data non-critical for boot |
| HDD btrfs | consistent with NVMe; autoScrub covers both |

## Source of truth

`hosts/desktop-1/disk-config.nix`
`hosts/desktop-1/default.nix` (zramSwap, autoScrub)
`modules/disk-health.nix` (smartd, 所有主机共享)
