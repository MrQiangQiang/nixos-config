{ osConfig, ... }:
{
  programs.opencode = {
    enable = true;
    settings = {
      model = "opencode-go/deepseek-v4-flash";
      provider."opencode-go".options.apiKey = "{file:${osConfig.age.secrets."opencode-go-key".path}}";
    };
    tui.theme = "system";
  };
}
