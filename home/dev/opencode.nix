{ osConfig, ... }:
{
  programs.opencode = {
    enable = true;
    # Auto-merge programs.mcp.servers (SSOT) into opencode config
    enableMcpIntegration = true;
    settings = {
      model = "opencode-go/deepseek-v4-flash";
      provider."opencode-go".options.apiKey = "{file:${osConfig.age.secrets."opencode-go-key".path}}";
    };
    tui.theme = "system";
  };
}
