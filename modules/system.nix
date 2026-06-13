{ config, pkgs, lib, ...}:
{
  # OOM killer — prevents system lockup under memory pressure
  systemd.oomd.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.nix-ld = {
    enable = true;
    libraries = [];
  };

  networking.getaddrinfo.precedence = {
    "::1/128" = 50;
    "::/0" = 40;
    "2002::/16" = 30;
    "::/96" = 20;
    "::ffff:0:0/96" = 100;
  };

  # mDNS — useful for Tailscale local name resolution and service discovery
  networking.networkmanager.connectionConfig = {
    "connection.mdns" = 2;
  };
}
