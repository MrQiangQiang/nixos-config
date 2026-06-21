# AI agent configuration SSOT
#
# Centralizes MCP server configuration and agent deployment rules.
# Individual agent settings (model, API keys) remain in home/dev/.
{ ... }:
{
  imports = [ ./mcp-servers.nix ];
}
