{
  config,
  pkgs,
  lib,
  ...
}:
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

  # nix-ld — 为未打包的预编译二进制提供 FHS 兼容的动态链接器。
  # libraries 不能为空,否则 nix-ld 虽启用但无任何库可用。
  # stdenv.cc.cc.lib 提供 libstdc++.so(预编译二进制最常见依赖)。
  programs.nix-ld = {
    enable = true;
    libraries = [ pkgs.stdenv.cc.cc.lib ];
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

  # Periodic TRIM for SSD health
  services.fstrim.enable = true;

  # systemd-resolved — DNS stub resolver, required for Tailscale MagicDNS integration.
  # Without this, Tailscale overwrites /etc/resolv.conf with only MagicDNS (100.100.100.100),
  # discarding any fallback nameservers and breaking DNS when Tailscale is disconnected.
  # With resolved, Tailscale uses resolvectl(8) to add MagicDNS via the resolved API,
  # and networking.nameservers serves as the fallback DNS pool.
  services.resolved.enable = true;
}
