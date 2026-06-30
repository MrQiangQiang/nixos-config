# zoxide — smarter cd (Layer 0: no theme, pure directory jumper)
# No color config — zoxide outputs paths, the shell handles display.
{
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
  };
}
