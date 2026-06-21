{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/efi";
            };
          };
          boot = {
            size = "2G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@var_cache" = {
                  mountpoint = "/var/cache";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@var_log" = {
                  mountpoint = "/var/log";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@ollama" = {
                  mountpoint = "/var/lib/ollama";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
              };
            };
          };
        };
      };
    };

    # ── HDD: git-annex data storage (1TB, 5400 RPM) ──
    # Mounted at /data/annex — single source of truth for binary data.
    # nofail: don't block boot if HDD fails.
    # smartd monitors drive health (configured in modules/disk-health.nix).
    disk.data = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions.data = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "btrfs";
            mountpoint = "/data/annex";
            mountOptions = [
              "compress=zstd"
              "noatime"
              "nofail"
            ];
          };
        };
      };
    };
  };
}
