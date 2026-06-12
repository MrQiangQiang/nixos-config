{
  hostName,
  system,
  users ? { },
  extraModules ? [ ],
  inputs,
  ...
}:

inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs; };
  modules = [
    ../modules/locale.nix
    ../modules/core-utils.nix
    ../modules/fonts.nix
    ../modules/opencode.nix
    ../modules/system.nix
    ../modules/ssh.nix
    inputs.agenix.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
    {
      nixpkgs.overlays = [
        inputs.self.overlays.default
        inputs.nix-vscode-extensions.overlays.default
      ];
      nixpkgs.config.allowUnfree = true;

      networking.hostName = hostName;
      networking.nameservers = [ "223.5.5.5" "119.29.29.29" ];
      networking.networkmanager.enable = true;

      hardware.enableRedistributableFirmware = true;

      time.timeZone = "Asia/Shanghai";

      boot.loader = {
        systemd-boot = {
          enable = true;
          editor = true;             # 允许按 e 编辑内核参数，紧急时可加 nomodeset
          configurationLimit = 10;   # 防止 /boot 分区被世代填满
        };
        efi.canTouchEfiVariables = true;
        timeout = 3;                 # 菜单显示 3 秒，足够选择旧世代回退
      };

      nix.settings = {
        experimental-features = [ "nix-command" "flakes" ];
        trusted-users = [
          "root"
          "@wheel"
        ];
        substituters = [
          "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=10"
          "https://mirror.sjtu.edu.cn/nix-channels/store?priority=20"
          "https://mirrors.ustc.edu.cn/nix-channels/store?priority=30"
          "https://cache.nixos.org?priority=40"
        ];
      };

      users.users = users;

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
      };
    }
  ] ++ extraModules;
}
