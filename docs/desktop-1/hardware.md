# hardware

```
CPU:     Ryzen 9 9950X  16C/32T  4.3-5.7 GHz  AM5  Zen5  SP 119
iGPU:    Radeon Graphics (Granite Ridge)  2 CU RDNA 3.5  2 GiB  PCI:115@0:0:0
dGPU:    RTX 5090 32 GiB GDDR7 (Gigabyte)  Blackwell  PCI:1@0:0:0  driver 595.80 open
RAM:     Kingbank 48 GiB ×2  DDR5-6400  dual-rank  SPD: 4800 JEDEC
NVMe:    Samsung 990 Pro 2 TiB  fw 8B2QJXD7  PCIe 4.0
MB:      ASUS TUF GAMING X870-PLUS WIFI  BIOS 1654  AGESA 1.3.0.1
PSU:     Seasonic VERTEX PX-1200  1200W  ATX 3.1  12V-2x6  80+ Platinum
Cooler:  360 mm AIO (钛钽 A090-360)
WiFi:    MT7925  (pcie_aspm=off required, band=5GHz locked — see below)
LAN:     RTL8126 2.5 GbE

## MT7925 known issue

mt7925e 驱动在 Linux v7.1.x 仍有未修复的 list corruption bug，由
band-steering roaming（2.4GHz ↔ 5GHz AP 切换）触发内核 crash。
Zac Bowling patch 0002/0012 已合并到 v7.1，但 crash 仍存在（另一个 bug）。
Workaround: NetworkManager `band=a` 锁定 5GHz 单 AP，消除 roaming 触发。
位置: `hosts/desktop-1/default.nix` → `wifi-mt7925-roaming-workaround.service`
移除条件: mt7925 roaming 路径修复进入 stable 内核。
Ref: https://zbowling.github.io/mt7925/issues/crash-analysis/
```

SP 119 = above-average silicon. Cooler score 156 = sufficient for PBO Motherboard limits.
