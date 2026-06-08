{ config, lib, pkgs, osConfig, ... }:

let
  isDesktopEnabled = osConfig.custom.desktop.enable or false;
in
lib.mkIf isDesktopEnabled {
  programs.starship = {
    enable = true;
    settings = {
      format = "$directory$git_branch$git_status$fill$cmd_duration$line_break$character";
      add_newline = true;

      # Layer 0: ANSI color names resolve through foot's 16-color palette.
      # When darkman switches foot between dark/light, ANSI colors update
      # automatically — no darkman entry needed for starship.
      #
      # foot ANSI → Rose Pine mapping:
      #   blue=pine  red=love  magenta=iris  cyan=rose
      #   green=foam  yellow=gold  black=overlay  white=text
      directory = {
        style = "fg:blue bg:black";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
      };

      git_branch = {
        style = "fg:blue bg:none";
        format = "[ $symbol $branch ]($style)";
        symbol = "";
      };

      git_status.style = "fg:red bg:none";

      character = {
        success_symbol = "[❯](bold fg:magenta)";
        error_symbol = "[❯](bold fg:red)";
      };

      cmd_duration = {
        style = "fg:cyan bg:none";
        min_time = 2000;
      };

      fill.symbol = " ";

      line_break.disabled = false;

      c.style = "fg:blue";
      rust.style = "fg:blue";
      nodejs.style = "fg:blue";
      python.style = "fg:blue";
      golang.style = "fg:blue";
      java.style = "fg:blue";
    };
  };
}
