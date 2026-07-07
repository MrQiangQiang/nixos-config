{
  hostName,
  system,
  users ? { },
  extraModules ? [ ],
  inputs,
  ...
}:

let
  lib = inputs.nixpkgs.lib;
in
lib.nixosSystem {
  specialArgs = { inherit inputs; };
  modules = [
    ../modules/locale.nix
    ../modules/core-utils.nix
    ../modules/disk-health.nix
    ../modules/fonts.nix
    ../modules/ai-secrets.nix
    ../modules/system.nix
    ../modules/ssh.nix
    ../modules/users.nix
    ../modules/cleanup.nix
    ../modules/git-annex.nix
    # ollama.nix: options 全局可见（nixpkgs module-list.nix 模式），
    # config 由 lib.mkIf cfg.enable 按需激活。home-manager 层直接读
    # osConfig.custom.ollama.* 无需 fallback，消除 SSOT 值重复。
    ../modules/ollama.nix
    inputs.agenix.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
    {
      nixpkgs.overlays = [
        inputs.self.overlays.default
        inputs.nix-vscode-extensions.overlays.default
      ];
      nixpkgs.config.allowUnfree = true;
      nixpkgs.hostPlatform = system;

      networking.hostName = hostName;
      networking.networkmanager.enable = lib.mkDefault true;
      networking.firewall.enable = lib.mkDefault true;

      hardware.enableRedistributableFirmware = true;

      environment.variables = {
        EDITOR = "hx";
        VISUAL = "hx";
      };

      time.timeZone = lib.mkDefault "Asia/Shanghai";

      boot.loader = {
        systemd-boot = {
          enable = lib.mkDefault true;
          # 允许在启动时编辑内核参数(可获 root)。
          # 个人桌面可接受(物理访问=root,FDE 才是正确缓解);
          # 服务器应覆盖为 false。
          editor = lib.mkDefault true;
          configurationLimit = 10;
        };
        efi.canTouchEfiVariables = lib.mkDefault true;
        timeout = lib.mkDefault 3;
      };

      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          "root"
          "@wheel"
        ];
        substituters = lib.mkDefault [
          "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=10"
          "https://mirror.sjtu.edu.cn/nix-channels/store?priority=20"
          "https://mirrors.ustc.edu.cn/nix-channels/store?priority=30"
          "https://cache.nixos.org?priority=40"
        ];
      };

      # Flakes 时代禁用传统 channel,避免双来源(唯一来源原则)
      nix.channel.enable = false;

      users.users = users;

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inherit inputs; };
        backupFileExtension = "hm-bak";
        users.fugui = {
          imports = [ ../home ];
        };
      };
    }
  ]
  ++ extraModules;
}
