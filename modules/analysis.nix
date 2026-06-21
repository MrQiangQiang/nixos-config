# System cleanup and maintenance.
# Imported globally via lib/mkHost.nix (applies to all hosts).
#
# Cleanup schedule:
#   - Nix store GC: weekly, delete generations older than 30d
#   - Nix store optimise: automatic (after each build)
#   - /tmp: clean files older than 10d
#   - /var/tmp: clean files older than 30d
#   - Docker: prune unused resources older than 30d (conditional on docker.enable)
{ config, lib, ... }:
{
  # ── Nix store cleanup ──
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;

  # ── Temporary directory cleanup ──
  # Age field cleans files older than the specified duration.
  systemd.tmpfiles.rules = [
    "d /tmp 1777 root root 10d -"
    "d /var/tmp 1777 root root 30d -"
  ];

  # ── Docker prune (conditional) ──
  # Only active when virtualisation.docker is enabled.
  # Prunes unused containers, images, networks, and volumes older than 30d (720h).
  systemd.timers.docker-prune = lib.mkIf config.virtualisation.docker.enable {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
  systemd.services.docker-prune = lib.mkIf config.virtualisation.docker.enable {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.virtualisation.docker.package}/bin/docker system prune -af --filter until=720h";
    };
  };
}
