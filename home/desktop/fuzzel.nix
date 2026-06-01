{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  d = palette.dark;
  l = palette.dawn;
  mkFuzzelConfig = colors: {
    main = {
      font = "monospace:size=12";
      prompt = "> ";
      dpi-aware = "auto";
    };
    colors = {
      background = "${colors.overlay}ff";
      text = "${colors.text}ff";
      match = "${colors.rose}ff";
      selection = "${colors.highlight_med}ff";
      selection-text = "${colors.text}ff";
    };
  };
in
lib.mkIf isDesktopEnabled {
  home.packages = [ pkgs.fuzzel ];

  xdg.configFile."theme/fuzzel-config-dark.ini" = {
    source = pkgs.writeText "fuzzel-config-dark.ini" (
      lib.generators.toINI {} (mkFuzzelConfig d)
    );
  };

  xdg.configFile."theme/fuzzel-config-light.ini" = {
    source = pkgs.writeText "fuzzel-config-light.ini" (
      lib.generators.toINI {} (mkFuzzelConfig l)
    );
  };
}
