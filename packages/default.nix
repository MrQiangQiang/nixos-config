{
  perSystem = { pkgs, ... }: {
    packages = {
      kwm = pkgs.callPackage ./kwm.nix { };
      kwim = pkgs.callPackage ./kwim.nix { };
      river = pkgs.callPackage ./river.nix { };
      trae-cn = pkgs.callPackage ./trae-cn.nix { };
      obsidian = pkgs.obsidian; # from overlay (prev.obsidian + overrideAttrs)
    };
  };

  flake.overlays.default = final: prev: {
    kwm = final.callPackage ./kwm.nix { };
    kwim = final.callPackage ./kwim.nix { };
    river = final.callPackage ./river.nix { };
    trae-cn = final.callPackage ./trae-cn.nix { };
    # import + prev.obsidian avoids circular dependency (callPackage would
    # auto-fill obsidian from final.obsidian = this very definition).
    obsidian = (import ./obsidian.nix) prev.obsidian;

    # trae-cn 是预编译 Electron 应用,运行时依赖 openssl 1.1(EOL,有已知漏洞)。
    # nixpkgs 在 openssl_1_1 的 meta.knownVulnerabilities 中标记了这些漏洞,
    # 会导致 nix build 报错。此处移除 knownVulnerabilities 以允许构建。
    # 安全缓解:仅在 trae-cn 的 buildFHSEnv 沙箱内使用,不暴露给系统其他部分。
    openssl_1_1_unsecure = prev.openssl_1_1.overrideAttrs (old: {
      meta = builtins.removeAttrs old.meta [ "knownVulnerabilities" ];
    });

    # ── AI 工具版本覆盖（当 nixpkgs 滞后时在此 override） ──
    # 示例：opencode 升级到最新版
    # opencode = prev.opencode.overrideAttrs (_: {
    #   version = "1.17.11";
    #   src = prev.fetchurl {
    #     url = "https://registry.npmjs.org/opencode-ai/-/opencode-ai-1.17.11.tgz";
    #     hash = "sha256-XXXX";  # nix build 会提示正确 hash
    #   };
    # });
    # 同理可覆盖 codex、claude-code
  };
}
