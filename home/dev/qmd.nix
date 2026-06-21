# QMD — local markdown search engine (Karpathy LLM Wiki pattern)
#
# Architecture:
#   - qmd binary from flake input (inputs.qmd.packages.${system}.default)
#   - Knowledge base at ~/knowledge/ — plain git repo, auto-cloned on activation.
#     git@github.com:MrQiangQiang/knowledge.git (markdown files, Obsidian-compatible)
#   - Index DB at ~/.cache/qmd/index.sqlite (auto-managed)
#   - Model cache at ~/.cache/qmd/models/ (auto-managed): Qwen3-Embedding-0.6B + Reranker + query-expansion
#   - Config at ~/.config/qmd/index.yml (declarative, read-only symlink)
#   - MCP HTTP server on localhost:8181 (systemd user service, foreground)
#   - Index refresh every 5 min (systemd user timer, incremental)
#
# Only enabled on desktop-1 (7x24, model inference).
# Non-desktop-1 machines access qmd MCP via Tailscale Serve:
#   desktop-1: tailscale serve --bg 8181
#   laptop-1:  programs.mcp.servers.qmd.url = https://desktop-1.tail0f7af0.ts.net/mcp
# (URL forks automatically in mcp-servers.nix via config.custom.qmd.enable.)
#
# ~/knowledge/ is git-cloned on ALL machines (for Obsidian browsing, AGENTS.md).
# The activation clone is idempotent — skips if .git/ already exists.
#
# Default models are overridden for Chinese support:
#   embed:   Qwen3-Embedding-0.6B (multilingual, 0.6B)
#   rerank:  Qwen3-Reranker-0.6B (default, multilingual)
#   generate: qmd-query-expansion-1.7B (default, query expansion)
{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.custom.qmd;

  qmdPkg = inputs.qmd.packages.${pkgs.system}.default;

  # qmd wrapper with correct LD_LIBRARY_PATH.
  # Upstream qmd package's makeWrapper only sets sqlite in LD_LIBRARY_PATH,
  # missing libstdc++ which is required by node-llama-cpp's prebuilt .node
  # binaries (FHS-linked ELF). Without this, `qmd embed` fails with
  # NoBinaryFoundError. We bypass the wrapper and call bun directly.
  qmdFixed = pkgs.writeShellScriptBin "qmd" ''
    export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.sqlite.out}/lib"
    exec ${pkgs.bun}/bin/bun ${qmdPkg}/lib/qmd/src/cli/qmd.ts "$@"
  '';
  qmdBin = "${qmdFixed}/bin/qmd";

  # Multilingual embedding model (Chinese + English)
  # Override default embeddinggemma-300M (English-only) for Chinese KB
  embedModel = "hf:Qwen/Qwen3-Embedding-0.6B-GGUF/Qwen3-Embedding-0.6B-Q8_0.gguf";

  knowledgeDir = "${config.home.homeDirectory}/knowledge";
in
{
  options.custom.qmd = {
    enable = lib.mkEnableOption "QMD local search engine";
  };

  config = lib.mkMerge [
    {
      # knowledge repo clone runs on ALL machines (Obsidian browsing, AGENTS.md).
      # idempotent: skips if ~/knowledge/.git already exists.
      # entryAfter writeSshConfig ensures ~/.ssh/config is in place for git clone.
      home.activation.ensureKnowledgeRepo = lib.hm.dag.entryAfter [ "writeSshConfig" ] ''
        if [ ! -d "$HOME/knowledge/.git" ]; then
          if $DRY_RUN_CMD git clone git@github.com:MrQiangQiang/knowledge.git "$HOME/knowledge"; then
            :
          else
            echo "Warning: knowledge repo clone failed, run manually later:" >&2
            echo "  git clone git@github.com:MrQiangQiang/knowledge.git ~/knowledge" >&2
          fi
        fi
      '';
    }

    (lib.mkIf cfg.enable {
      home.packages = [ qmdFixed ];

      # Declarative qmd config (read-only symlink to Nix store)
      # Changes to collections/contexts must go through this file.
      home.file.".config/qmd/index.yml".text = ''
        # QMD collections configuration (managed by NixOS)
        global_context: "Personal knowledge base — raw sources and AI-generated wiki"

        collections:
          knowledge:
            path: ${knowledgeDir}
            pattern: "**/*.md"
            context:
              "/raw/articles": "Source articles (blog posts, web clippings)"
              "/raw/papers": "Academic papers and research documents"
              "/raw/notes": "Personal notes and meeting transcripts"
              "/raw/transcripts": "Audio/video transcripts"
              "/wiki": "AI-generated wiki pages (summaries, concepts, indexes)"
              "/": "Knowledge base root"
      '';

      # Knowledge directory structure (writable, created on activation)
      # Layout follows Karpathy LLM Wiki pattern: raw/ (immutable) + wiki/ (AI-generated)
      home.activation.qmdKnowledgeDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p \
          ${knowledgeDir}/raw/articles \
          ${knowledgeDir}/raw/papers \
          ${knowledgeDir}/raw/notes \
          ${knowledgeDir}/raw/transcripts \
          ${knowledgeDir}/raw/assets \
          ${knowledgeDir}/wiki
      '';

      # MCP HTTP server (foreground, managed by systemd)
      # Endpoint: http://localhost:8181/mcp
      # Models stay loaded in VRAM across requests (5 min idle timeout)
      # QMD_FORCE_CPU=1: skip GPU probe (node-llama-cpp prebuilt lacks GPU support
      # in NixOS; probe triggers NoBinaryFoundError)
      systemd.user.services.qmd-mcp = {
        Unit = {
          Description = "QMD MCP HTTP server (localhost:8181)";
        };
        Service = {
          ExecStart = "${qmdBin} mcp --http --port 8181";
          Environment = [
            "QMD_EMBED_MODEL=${embedModel}"
            "QMD_FORCE_CPU=1"
          ];
          Restart = "on-failure";
          RestartSec = 10;
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      # Index refresh (incremental, every 5 min)
      # qmd update: rebuild keyword index (fast)
      # qmd embed: rebuild embedding index (incremental, only new/changed docs)
      systemd.user.services.qmd-refresh = {
        Unit = {
          Description = "QMD index refresh (incremental)";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.bash}/bin/bash -lc '${qmdBin} update && ${qmdBin} embed'";
          Environment = [
            "QMD_EMBED_MODEL=${embedModel}"
            "QMD_FORCE_CPU=1"
          ];
        };
      };
      systemd.user.timers.qmd-refresh = {
        Timer = {
          OnBootSec = "5min";
          OnUnitActiveSec = "5min";
          Persistent = true;
        };
        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    })
  ];
}
