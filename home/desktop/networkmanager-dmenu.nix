{ config, lib, pkgs, osConfig, palette, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
  d = palette.dark;
  l = palette.dawn;

  mkNmdmConfig = colors: {
    dmenu = {
      dmenu_command = "fuzzel --dmenu";
      active_chars = "==";
      highlight = "True";
      compact = "True";
      wifi_icons = "󰤯󰤟󰤢󰤥󰤨";
      format = "{icon} {name} {sec}";
      list_saved = "False";
      prompt = "WiFi";
    };
    dmenu_passphrase = {
      obscure = "True";
      obscure_color = colors.base;
    };
    editor = {
      terminal = "foot";
      gui_if_available = "True";
      gui = "nm-connection-editor";
    };
    nmdm = {
      rescan_delay = "5";
      show_notifications = "True";
    };
  };
in
lib.mkIf isDesktopEnabled {
  home.packages = [ pkgs.networkmanager_dmenu ];

  # networkmanager-dmenu config: use fuzzel as the menu backend.
  # Dark/light INI generation follows fuzzel.nix pattern:
  #   Nix generates to ~/.config/theme/ → darkman ln -sf switches.
  # Password: NO pinentry — networkmanager-dmenu source L420-L423
  # natively supports fuzzel --password. Setting pinentry intercepts
  # get_passphrase() before that fallback.

  xdg.configFile."theme/networkmanager-dmenu-config-dark.ini" = {
    source = pkgs.writeText "networkmanager-dmenu-config-dark.ini" (
      lib.generators.toINI {} (mkNmdmConfig d)
    );
  };

  xdg.configFile."theme/networkmanager-dmenu-config-light.ini" = {
    source = pkgs.writeText "networkmanager-dmenu-config-light.ini" (
      lib.generators.toINI {} (mkNmdmConfig l)
    );
  };
}
