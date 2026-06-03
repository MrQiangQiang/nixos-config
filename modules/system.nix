{ config, pkgs, lib, ...}:
{
  services.logind = {
    suspendKey = "suspend";
    lidSwitch = "suspend";
    lidSwitchDocked = "ignore";
  };

  # Compressed swap in RAM — no disk IO, no SSD wear
  # Recommended by NixOS Wiki for systems with enough RAM
  zramSwap.enable = true;

  # OOM killer — required by NixOS Wiki when using zram swap
  # Prevents system lockup when zram capacity is exhausted
  systemd.oomd.enable = true;

  services.upower.enable = true;

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
}


