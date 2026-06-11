# yazi — terminal file manager (Layer 0: auto-follows terminal via OSC 11)
#
# Architecture (build-time: same pattern as bat.nix):
#   palette.nix → replaceVars templates → programs.yazi.flavors → [flavor] dark/light
#   Yazi startup → OSC 11 → auto-selects flavor.dark or flavor.light
#
# Runtime behavior differs from bat:
#   - bat: CLI tool, new process each invocation → re-detects OSC 11 every time
#     → darkman toggle → next `bat` automatically correct
#   - yazi: persistent TUI process → EMULATOR.light is RoCell (one-time at startup)
#     → running instances do NOT switch; must quit and restart
#
# No darkman entry needed — yazi follows the terminal at startup.
# Running instances do NOT switch (hex colors don't follow terminal palette).
# This is acceptable: file managers are short-session apps, new instances are correct.
#
# Icon colors integrated via [icon] section in flavor.toml template.
# De-emphasized colors match official Rose Pine: highlight_low for dim icons, overlay for dll.
{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;

  # flavor.toml uses: base surface overlay muted subtle text love gold rose pine foam iris highlight_low highlight_high
  # tmtheme.xml uses: name base surface highlight_low highlight_med highlight_high subtle text gold pine foam rose iris love
  mkFlavorVars = c: {
    inherit (c) base surface overlay muted subtle text love gold rose pine foam iris
      highlight_low highlight_high;
  };

  mkTmThemeVars = c: extra:
    {
      inherit (c) base surface highlight_low highlight_med highlight_high subtle
        text gold pine foam rose iris love;
    } // extra;

  darkFlavor = pkgs.replaceVars ./config/rose-pine-yazi-flavor.toml (mkFlavorVars palette.dark);
  dawnFlavor = pkgs.replaceVars ./config/rose-pine-yazi-flavor.toml (mkFlavorVars palette.dawn);
  darkTmTheme = pkgs.replaceVars ./config/rose-pine-yazi-tmtheme.xml (mkTmThemeVars palette.dark {
    name = if palette.dark_variant == "moon" then "Rosé Pine Moon" else "Rosé Pine";
    semantic_class = if palette.dark_variant == "moon" then "theme.dark.rosé-pine-moon" else "theme.dark.rosé-pine";
    uuid = if palette.dark_variant == "moon" then "CC28B8FB-96BA-43EB-B71F-5AA3D3EBB0BB" else "14991673-80EB-41A2-BEFF-03216A233730";
  });
  dawnTmTheme = pkgs.replaceVars ./config/rose-pine-yazi-tmtheme.xml (mkTmThemeVars palette.dawn {
    name = "Rosé Pine Dawn";
    semantic_class = "theme.light.rosé-pine-dawn";
    uuid = "BB4B4616-E742-41D5-BB5B-63D45FA614F";
  });

  # Build flavor as a derivation with real files (not nix store symlinks).
  # Each flavor directory contains flavor.toml + tmtheme.xml.
  mkFlavorPkg = name: flavor: tmtheme:
    pkgs.runCommand "yazi-flavor-${name}" {} ''
      mkdir $out
      cp ${flavor} $out/flavor.toml
      cp ${tmtheme} $out/tmtheme.xml
    '';

  darkFlavorName = palette.yazi.dark;
  lightFlavorName = palette.yazi.light;
in
lib.mkIf isDesktopEnabled {
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    settings = {
      mgr = {
        sort_by = "natural";
        sort_sensitive = true;
        sort_dir_first = true;
        show_hidden = true;
        show_symlink = false;
        ratio = [ 1 3 4 ];
        linemode = "size_and_mtime";
        scrolloff = 5;
      };
    };
    flavors = {
      ${darkFlavorName} = mkFlavorPkg darkFlavorName darkFlavor darkTmTheme;
      ${lightFlavorName} = mkFlavorPkg lightFlavorName dawnFlavor dawnTmTheme;
    };
    theme.flavor = {
      dark = darkFlavorName;
      light = lightFlavorName;
    };
    initLua = ''
      function Linemode:size_and_mtime()
        local time = math.floor(self._file.cha.mtime or 0)
        if time == 0 then
          time = ""
        elseif os.date("%Y", time) == os.date("%Y") then
          time = os.date("%b %d %H:%M", time)
        else
          time = os.date("%b %d  %Y", time)
        end

        local size = self._file:size()
        return string.format("%s %s", size and ya.readable_size(size) or "-", time)
      end
    '';
  };

  home.packages = with pkgs; [
    thunar
    tumbler
    gvfs
    ffmpegthumbnailer
    poppler-utils
    unrar
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "thunar.desktop" ];
    };
  };

  xdg.dataFile."icons/hicolor/scalable/apps/yazi.svg".source = ./filemanager.svg;
}
