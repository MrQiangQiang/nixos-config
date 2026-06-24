{ config, lib, pkgs, osConfig, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
in
lib.mkIf isDesktopEnabled {
  # WAYLAND_DISPLAY from systemd manager environment (set by import-environment)
  # is the single source of truth — always current, survives reexec.
  systemd.user.services.kanshi = {
    Unit.ConditionEnvironment = lib.mkForce "WAYLAND_DISPLAY";
    Unit.StartLimitIntervalSec = 0;
    Service.Environment = [ "XDG_RUNTIME_DIR=/run/user/%U" ];
  };
  services.kanshi = {
    enable = true;
    settings = [
      {
        profile.name = "laptop";
        profile.outputs = [{
          criteria = "eDP-1";
          status = "enable";
        }];
      }
      {
        # 使用 EDID 描述（make model serial）而非输出名称，避免 GPU 驱动变化导致命名漂移。
        # 之前用 "HDMI-A-1"，但添加 videoDrivers=[nvidia] 后 NVIDIA 占用了
        # HDMI-A-1 名称，AMD iGPU 输出变为 HDMI-A-2，导致 no profile matched。
        # kanshi 匹配规则（main.c match_profile_output）：
        #   1. "*" 通配符
        #   2. 精确匹配输出名称（如 "HDMI-A-2"，不稳定）
        #   3. fnmatch "make model serial"（如 "Xiaomi Corporation Mi Monitor *"）
        # 使用 make+model 通配 serial，更换同型号显示器无需改配置。
        profile.name = "desktop";
        profile.outputs = [{
          criteria = "Xiaomi Corporation Mi Monitor *";
          mode = "3840x2160@60";
          scale = 2.0;
          status = "enable";
        }];
      }
    ];
  };
}
