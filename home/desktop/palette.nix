{ osConfig, ... }:

let
  dark_variant = osConfig.custom.desktop.dark_variant or "main";

  main = {
    base = "191724";
    surface = "1f1d2e";
    overlay = "26233a";
    muted = "6e6a86";
    subtle = "908caa";
    text = "e0def4";
    love = "eb6f92";
    gold = "f6c177";
    rose = "ebbcba";
    pine = "31748f";
    foam = "9ccfd8";
    iris = "c4a7e7";
    highlight_low = "21202e";
    highlight_med = "403d52";
    highlight_high = "524f67";

    # bright variants — lighter versions of regular colors (from official foot theme)
    bright_overlay = "47435d";
    bright_love    = "ff98ba";
    bright_foam    = "c5f9ff";
    bright_gold    = "ffeb9e";
    bright_pine    = "5b9ab7";
    bright_iris    = "eed0ff";
    bright_rose    = "ffe5e3";
    bright_text    = "fefcff";
  };

  moon = {
    base = "232136";
    surface = "2a273f";
    overlay = "393552";
    muted = "6e6a86";
    subtle = "908caa";
    text = "e0def4";
    love = "eb6f92";
    gold = "f6c177";
    rose = "ea9a97";
    pine = "3e8fb0";
    foam = "9ccfd8";
    iris = "c4a7e7";
    highlight_low = "2a283e";
    highlight_med = "44415a";
    highlight_high = "56526e";
    # bright variants — lighter versions of regular colors (from official foot theme)
    bright_overlay = "5c5776";
    bright_love    = "ff98ba";
    bright_foam    = "c5f9ff";
    bright_gold    = "ffeb9e";
    bright_pine    = "6ab7d9";
    bright_iris    = "eed0ff";
    bright_rose    = "ffc3bf";
    bright_text    = "fefcff";
  };

  dawn = {
    base = "faf4ed";
    surface = "fffaf3";
    overlay = "f2e9e1";
    muted = "9893a5";
    subtle = "797593";
    text = "575279";
    love = "b4637a";
    gold = "ea9d34";
    rose = "d7827e";
    pine = "286983";
    foam = "56949f";
    iris = "907aa9";
    highlight_low = "f4ede8";
    highlight_med = "dfdad9";
    highlight_high = "cecacd";
    # bright variants — lighter versions of regular colors (from official foot theme)
    bright_overlay = "fffdf5";
    bright_love    = "df8aa0";
    bright_foam    = "7ebcc7";
    bright_gold    = "ffc55c";
    bright_pine    = "538faa";
    bright_iris    = "b8a1d2";
    bright_rose    = "ffaaa5";
    bright_text    = "7c76a0";
  };

  dark = if dark_variant == "moon" then moon else main;

  # Linux console palette escape sequences (\033]PNRRGGBB).
  # ANSI slot mapping aligned with foot (not official linux-tty):
  #   P0=overlay P1=love P2=foam P3=gold P4=pine P5=iris P6=rose P7=text
  #   P8=muted P9-PF=bright variants
  mkTtyEscapes = c:
    "\\033]P0${c.overlay}\\033]P1${c.love}\\033]P2${c.foam}\\033]P3${c.gold}\\033]P4${c.pine}\\033]P5${c.iris}\\033]P6${c.rose}\\033]P7${c.text}\\033]P8${c.muted}\\033]P9${c.bright_love}\\033]PA${c.bright_foam}\\033]PB${c.bright_gold}\\033]PC${c.bright_pine}\\033]PD${c.bright_iris}\\033]PE${c.bright_rose}\\033]PF${c.bright_text}";

  # ANSI 16-color slot → Rose Pine color name mapping.
  # Single source of truth for ANSI-indirect color consumers (starship).
  # Slot mapping matches foot.nix regular0-7 and mkTtyEscapes P0-P7.
  #   black(0)=overlay  red(1)=love     green(2)=foam
  #   yellow(3)=gold    blue(4)=pine    magenta(5)=iris
  #   cyan(6)=rose      white(7)=text
  ansi = {
    overlay = "black";
    love    = "red";
    foam    = "green";
    gold    = "yellow";
    pine    = "blue";
    iris    = "magenta";
    rose    = "cyan";
    text    = "white";
  };

  gtk = {
    dark_name = if dark_variant == "moon" then "rose-pine-moon" else "rose-pine";
    light_name = "rose-pine-dawn";
  };

  vscode = {
    dark_name = if dark_variant == "moon" then "Rosé Pine Moon" else "Rosé Pine";
    light_name = "Rosé Pine Dawn";
  };

  tty = {
    dark = mkTtyEscapes dark;
    light = mkTtyEscapes dawn;
  };
in
{
  _file = ./palette.nix;
  inherit dark dawn gtk vscode dark_variant tty ansi;
}
