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
  s = palette.ansi;
in
lib.mkIf isDesktopEnabled {
  programs.starship = {
    enable = true;
    settings = {
      format = "$username$directory$git_branch$git_status$fill$c$elixir$elm$golang$haskell$java$julia$nodejs$nim$rust$scala$conda$python$time$cmd_duration$line_break$character";
      add_newline = true;

      # Layer 0: ANSI color names resolve through foot's 16-color palette.
      # When darkman switches foot between dark/light, ANSI colors update
      # automatically — no darkman entry needed for starship.
      # palette.ansi provides semantic names: s.pine → "blue" → foot's pine color.

      directory = {
        format = "[](fg:${s.overlay})[ $path ]($style)[](fg:${s.overlay}) ";
        style = "bg:${s.overlay} fg:${s.pine}";
        truncation_length = 3;
        truncation_symbol = "…/";
      };

      fill = {
        style = "fg:${s.overlay}";
        symbol = " ";
      };

      git_branch = {
        format = "[](fg:${s.overlay})[ $symbol $branch ]($style)[](fg:${s.overlay}) ";
        style = "bg:${s.overlay} fg:${s.foam}";
        symbol = "";
      };

      git_status = {
        disabled = false;
        style = "bg:${s.overlay} fg:${s.love}";
        format = "[](fg:${s.overlay})([$all_status$ahead_behind]($style))[](fg:${s.overlay}) ";
        up_to_date = "[ ✓ ](bg:${s.overlay} fg:${s.iris})";
        untracked = ''[?\($count\)](bg:${s.overlay} fg:${s.gold})'';
        stashed = ''[\$](bg:${s.overlay} fg:${s.iris})'';
        modified = ''[!\($count\)](bg:${s.overlay} fg:${s.gold})'';
        renamed = ''[»\($count\)](bg:${s.overlay} fg:${s.iris})'';
        deleted = ''[✘\($count\)](style)'';
        staged = ''[++\($count\)](bg:${s.overlay} fg:${s.gold})'';
        ahead = ''[⇡\($count\)](bg:${s.overlay} fg:${s.foam})'';
        diverged = ''⇕[\[](bg:${s.overlay} fg:${s.iris})[⇡\($ahead_count\)](bg:${s.overlay} fg:${s.foam})[⇣\($behind_count\)](bg:${s.overlay} fg:${s.rose})[\]](bg:${s.overlay} fg:${s.iris})'';
        behind = ''[⇣\($count\)](bg:${s.overlay} fg:${s.rose})'';
      };

      time = {
        disabled = false;
        format = "[](fg:${s.overlay})[ $time 󰴈 ]($style)[](fg:${s.overlay})";
        style = "bg:${s.overlay} fg:${s.rose}";
        time_format = "%I:%M%P";
        use_12hr = true;
      };

      username = {
        disabled = false;
        format = "[](fg:${s.overlay})[ 󰧱 $user ]($style)[](fg:${s.overlay}) ";
        show_always = true;
        style_root = "bg:${s.overlay} fg:${s.iris}";
        style_user = "bg:${s.overlay} fg:${s.iris}";
      };

      character = {
        success_symbol = "[❯](bold fg:${s.iris})";
        error_symbol = "[❯](bold fg:${s.love})";
      };

      cmd_duration = {
        style = "fg:${s.rose} bg:none";
        min_time = 2000;
      };

      line_break.disabled = false;

      # Languages — only shown when a matching project file is detected
      c = {
        style = "bg:${s.overlay} fg:${s.pine}";
        format = "[](fg:${s.overlay})[ $symbol$version ]($style)[](fg:${s.overlay})";
        symbol = " ";
      };
      elixir = {
        style = "bg:${s.overlay} fg:${s.pine}";
        format = "[](fg:${s.overlay})[ $symbol$version ]($style)[](fg:${s.overlay})";
        symbol = " ";
      };
      elm = {
        style = "bg:${s.overlay} fg:${s.pine}";
        format = "[](fg:${s.overlay})[ $symbol$version ]($style)[](fg:${s.overlay})";
        symbol = " ";
      };
      golang = {
        style = "bg:${s.overlay} fg:${s.pine}";
        format = "[](fg:${s.overlay})[ $symbol$version ]($style)[](fg:${s.overlay})";
        symbol = " ";
      };
      haskell = {
        style = "bg:${s.overlay} fg:${s.pine}";
        format = "[](fg:${s.overlay})[ $symbol$version ]($style)[](fg:${s.overlay})";
        symbol = " ";
      };
      java = {
        style = "bg:${s.overlay} fg:${s.pine}";
        format = "[](fg:${s.overlay})[ $symbol$version ]($style)[](fg:${s.overlay})";
        symbol = " ";
      };
      julia = {
        style = "bg:${s.overlay} fg:${s.pine}";
        format = "[](fg:${s.overlay})[ $symbol$version ]($style)[](fg:${s.overlay})";
        symbol = " ";
      };
      nodejs = {
        style = "bg:${s.overlay} fg:${s.pine}";
        format = "[](fg:${s.overlay})[ $symbol$version ]($style)[](fg:${s.overlay})";
        symbol = "󰎙 ";
      };
      nim = {
        style = "bg:${s.overlay} fg:${s.pine}";
        format = "[](fg:${s.overlay})[ $symbol$version ]($style)[](fg:${s.overlay})";
        symbol = "󰆥 ";
      };
      rust = {
        style = "bg:${s.overlay} fg:${s.pine}";
        format = "[](fg:${s.overlay})[ $symbol$version ]($style)[](fg:${s.overlay})";
        symbol = " ";
      };
      scala = {
        style = "bg:${s.overlay} fg:${s.pine}";
        format = "[](fg:${s.overlay})[ $symbol$version ]($style)[](fg:${s.overlay})";
        symbol = " ";
      };
      python = {
        style = "bg:${s.overlay} fg:${s.pine}";
        format = "[](fg:${s.overlay})[ $symbol$version ]($style)[](fg:${s.overlay})";
        symbol = " ";
      };
      conda = {
        style = "bg:${s.overlay} fg:${s.pine}";
        format = "[](fg:${s.overlay})[ $symbol$environment ]($style)[](fg:${s.overlay})";
        symbol = "🅒 ";
      };
    };
  };
}
