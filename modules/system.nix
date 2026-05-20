{ config, pkgs, lib, ...}:
{
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
  
  # 用于解决 Distrobox 与宿主机的通信问题
  services.flatpak.enable = true;
}


