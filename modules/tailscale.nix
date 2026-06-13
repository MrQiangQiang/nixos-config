{ config, pkgs, lib, ... }:
{
  services.tailscale.enable = true;

  networking.nameservers = lib.mkBefore [ "100.100.100.100" ];

  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
