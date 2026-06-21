{
  config,
  lib,
  pkgs,
  osConfig,
  palette,
  ...
}:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  d = palette.dark;
  l = palette.dawn;
  mkFuzzelConfig = colors: {
    main = {
      font = "monospace:size=12";
      prompt = "> ";
      dpi-aware = "auto";
      icon-theme = config.gtk.iconTheme.name;
    };
    colors = {
      background = "${colors.base}ff";
      text = "${colors.text}ff";
      prompt = "${colors.text}ff";
      placeholder = "${colors.muted}ff";
      input = "${colors.text}ff";
      match = "${colors.rose}ff";
      selection = "${colors.highlight_med}ff";
      selection-text = "${colors.text}ff";
      selection-match = "${colors.rose}ff";
      counter = "${colors.gold}ff";
      border = "${colors.rose}ff";
    };
  };
in
lib.mkIf isDesktopEnabled {
  home.packages = [ pkgs.fuzzel ];

  xdg.configFile."theme/fuzzel-config-dark.ini" = {
    source = pkgs.writeText "fuzzel-config-dark.ini" (lib.generators.toINI { } (mkFuzzelConfig d));
  };

  xdg.configFile."theme/fuzzel-config-light.ini" = {
    source = pkgs.writeText "fuzzel-config-light.ini" (lib.generators.toINI { } (mkFuzzelConfig l));
  };
}
