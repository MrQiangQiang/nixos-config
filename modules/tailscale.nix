{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.custom.tailnet.domain = lib.mkOption {
    type = lib.types.str;
    default = "tail0f7af0.ts.net";
    description = "Tailscale tailnet DNS name (assigned by Tailscale console, not changeable via Nix)";
  };

  config = {
    services.tailscale.enable = true;

    # Fallback DNS for systemd-resolved when Tailscale is disconnected.
    # MagicDNS (100.100.100.100) is automatically added by Tailscale via resolvctl(8)
    # when services.resolved is enabled — do NOT list it here.
    networking.nameservers = [
      "223.5.5.5"
      "119.29.29.29"
    ];

    networking.firewall.trustedInterfaces = [ "tailscale0" ];
  };
}
