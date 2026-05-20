{ config, pkgs, lib, ...}:
{
  service.upower.enable = true;
  
  service.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}


