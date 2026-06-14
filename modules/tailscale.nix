{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.tailscale.enable = true;

  # Fallback DNS for systemd-resolved when Tailscale is disconnected.
  # MagicDNS (100.100.100.100) is automatically added by Tailscale via resolvectl(8)
  # when services.resolved is enabled — do NOT list it here.
  networking.nameservers = [
    "223.5.5.5"
    "119.29.29.29"
  ];

  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
