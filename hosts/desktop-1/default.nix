{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  keys = import ../../secrets/keys.nix;
in
{
  imports = [
    inputs.disko.nixosModules.disko
    ./disk-config.nix
    ../../modules/desktop.nix
    ../../modules/proxy.nix
    ../../modules/im.nix
    ../../modules/tailscale.nix
    ../../modules/ollama.nix
    ./hardware-configuration.nix
  ];

  system.stateVersion = "26.11";
  home-manager.users.fugui.home.stateVersion = "26.11";

  # ── Kernel ─────────────────────────────────────────────────

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "pcie_aspm=off"
    "amd_pstate=active"
    "modprobe.blacklist=nouveau"
    "nouveau.modeset=0"
  ];

  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # ── GPU: NVIDIA + AMD iGPU (PRIME Offload) ────────────────
  # 必须声明 videoDrivers，否则 hardware.nvidia 模块不激活，
  # GSP 固件不会安装到 /lib/firmware/nvidia/，导致 RmInitAdapter failed。
  # Blackwell (RTX 5090) 强制要求 open kernel module + GSP 固件。
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.cpu.amd.updateMicrocode = true;

  zramSwap.enable = true;

  # ── GPU: PRIME Offload ─────────────────────────────────────

  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      amdgpuBusId = "PCI:115@0:0:0";
      nvidiaBusId = "PCI:1@0:0:0";
    };
  };

  # iGPU OpenCL via Mesa rusticl (built-in, hardware.graphics.enable = true)

  # ── Ollama (本地 LLM 推理，CUDA) ──────────────────────────
  # 配置在 modules/ollama.nix，通过 options 参数化
  # 包含 KEEP_ALIVE=-1 永久驻留 + ollama-prewarm.service VRAM 预加载
  custom.ollama.enable = true;

  # ── Desktop ────────────────────────────────────────────────

  custom.desktop.enable = true;
  custom.desktop.dark_variant = "moon";

  # ── User ───────────────────────────────────────────────────

  # homeMode 比 laptop 更严格(共享基础配置见 modules/users.nix)
  users.users.fugui.homeMode = "750";

  # QMD 仅 desktop 启用(共享 home-manager 配置见 lib/mkHost.nix)
  home-manager.users.fugui.custom.qmd.enable = true;

  # ── Remote deploy ──────────────────────────────────────────
  # 通过 root SSH 密钥登录实现远程部署(nixos-rebuild --target-host root@desktop-1),
  # 替代旧的 wheelNeedsPassword=false(全 wheel 组免密 sudo = 完整 root 后门)。
  # 仅允许密钥登录(ProhibitRootLogin),部署密钥来自 laptop-1 的 fugui 用户。
  services.openssh.settings.PermitRootLogin = "prohibit-password";
  users.users.root.openssh.authorizedKeys.keys = [
    keys.users.fugui
  ];

  # ── Filesystem ─────────────────────────────────────────────

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [
      "/"
      "/data/annex"
    ];
    interval = "monthly";
  };

  # ── Tailscale Serve (QMD MCP) ──────────────────────────────
  # Exposes qmd-mcp (localhost:8181) to tailnet via HTTPS.
  # Requires HTTPS certificates enabled in Tailscale admin console:
  #   https://login.tailscale.com/admin/settings/general
  # (one-time per tailnet, not nixifiable — human auth required).
  # tailscale serve --bg stores config in tailscaled state;
  # survives reboot. Idempotent re-run on every activation.
  #
  # Boot race: tailscaled.service reports "active" before the node
  # reaches BackendState == Running (login + DERP + tailscale0 up).
  # `tailscale serve` called during that window fails with
  # "unexpected state: NoState". We gate on `tailscale status`
  # (returns 0 only at Running), mirroring nixpkgs' own
  # tailscaled-autoconnect unit. Restart=on-failure keeps retrying
  # until tailscale comes up (mihomo/Tailscale boot ordering).
  # Ref: https://github.com/tailscale/tailscale/issues/11504
  systemd.services.tailscale-serve-qmd = {
    description = "Tailscale Serve for QMD MCP (localhost:8181)";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.tailscale ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = 10;
    };
    script = ''
      for i in $(seq 1 60); do
        if tailscale status --peers=false >/dev/null 2>&1; then
          exec tailscale serve --bg localhost:8181
        fi
        sleep 1
      done
      echo "tailscale not online after 60s; will retry" >&2
      exit 1
    '';
  };

  # ── git-annex canonical repo initialization ───────────────
  # 幂等初始化 /data/annex 为 canonical git-annex 仓库。
  # 所有命令幂等(官方 man page 确认),安全重复执行。
  # ExecStartPre 的 `+` 前缀以 root 运行 chown(nofail 挂载点 tmpfiles 时序不可靠,
  # 改用 ExecStartPre+ 是 nixpkgs 实证模式,见 wgautomesh/unifi-os-server 模块)。
  # RequiresMountsFor 不依赖 disko 生成的具体挂载单元名,更稳健。
  systemd.services.git-annex-init = {
    description = "Initialize git-annex canonical repo at /data/annex";
    wantedBy = [ "multi-user.target" ];
    unitConfig.RequiresMountsFor = "/data/annex";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "fugui";
      Group = "users";
      WorkingDirectory = "/data/annex";
      ExecStartPre = [ "+${pkgs.coreutils}/bin/chown fugui:users /data/annex" ];
    };
    path = [
      pkgs.git
      pkgs.git-annex
    ];
    script = ''
      [ -d .git ] || git init
      git annex init "desktop-1"
      git annex group here backup
      git annex required here "present"
      git annex numcopies 1
      git annex mincopies 1
      git remote get-url origin 2>/dev/null || \
        git remote add origin git@github.com:MrQiangQiang/annex.git
    '';
  };
}
