{ osConfig, ... }:
{
  programs.opencode = {
    enable = true;
    # Auto-merge programs.mcp.servers (SSOT) into opencode config
    enableMcpIntegration = true;
    settings = {
      model = "opencode-go/deepseek-v4-flash";
      provider = {
        "opencode-go".options.apiKey = "{file:${osConfig.age.secrets."opencode-go-key".path}}";
        "ollama" = {
          npm = "@ai-sdk/openai-compatible";
          name = "Ollama (local)";
          options.baseURL = "http://localhost:11434/v1";
          models."qwen3.6:27b-q4_K_M".name = "Qwen3.6 27B (Q4_K_M)";
        };
      };
    };
    tui.theme = "system";
  };
}
