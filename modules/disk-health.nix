{ pkgs, ... }:
{
  # 硬件健康监测:smartd 自动监控所有 SMART 设备(HDD + NVMe SSD)
  # autodetect 默认 true,DEVICESCAN 自动扫描 /dev/sd* 和 /dev/nvme*
  services.smartd.enable = true;

  # 手动查看工具(services.smartd 不会自动提供 smartctl)
  environment.systemPackages = with pkgs; [
    smartmontools
  ];
}
