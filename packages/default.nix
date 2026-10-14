{
  perSystem = { pkgs, ... }: {
    packages = {
      kwm = pkgs.callPackage ./kwm.nix { };
      kwim = pkgs.callPackage ./kwim.nix { };
      river = pkgs.callPackage ./river.nix { };
      trae-cn = pkgs.callPackage ./trae-cn.nix { };
      obsidian = pkgs.obsidian; # from overlay (prev.obsidian + overrideAttrs)
      rose-pine-gtk-theme = pkgs.callPackage ./rose-pine-gtk-theme.nix { };
    };
  };

  flake.overlays.default = final: prev: {
    kwm = final.callPackage ./kwm.nix { };
    kwim = final.callPackage ./kwim.nix { };
    river = final.callPackage ./river.nix { };
    trae-cn = final.callPackage ./trae-cn.nix { };
    rose-pine-gtk-theme = final.callPackage ./rose-pine-gtk-theme.nix { };
    # import + prev.obsidian avoids circular dependency (callPackage would
    # auto-fill obsidian from final.obsidian = this very definition).
    obsidian = (import ./obsidian.nix) prev.obsidian;
  };
}
