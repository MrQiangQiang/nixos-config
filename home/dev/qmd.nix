# QMD — local markdown search engine (Karpathy LLM Wiki pattern)
#
# Architecture:
#   - qmd binary from flake input (inputs.qmd.packages.${system}.default)
#   - Collections:
#     1. ~/knowledge/ — personal knowledge base (Karpathy LLM Wiki: raw/ + wiki/)
#        git@github.com:MrQiangQiang/knowledge.git (markdown files, Obsidian-compatible)
#     2. ~/nixos-config/docs/ — NixOS configuration documentation
#        (architecture, decisions, host-specific docs)
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
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.custom.qmd;

  qmdPkg = inputs.qmd.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # qmd wrapper with correct LD_LIBRARY_PATH.
  # Upstream qmd package's makeWrapper only sets sqlite in LD_LIBRARY_PATH,
  # missing libstdc++ (required by node-llama-cpp's prebuilt .node binaries)
  # and CUDA libraries (required for GPU acceleration).
  # - /run/opengl-driver/lib: libcuda.so, libnvidia-ml.so (NVIDIA driver)
  # - cuda_cudart: libcudart.so.13 (CUDA 13 runtime, matches prebuilt binary)
  # - libcublas.lib: libcublas.so.13 + libcublasLt.so.13 (CUDA 13 BLAS)
  #   Note: libcublas has split outputs; libraries are in the .lib output.
  #   Note: node-llama-cpp prebuilt CUDA binary requires CUDA 13 (not 12).
  qmdFixed = pkgs.writeShellScriptBin "qmd" ''
    export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.sqlite.out}/lib:/run/opengl-driver/lib:${pkgs.cudaPackages_13.cuda_cudart}/lib:${pkgs.cudaPackages_13.libcublas.lib}/lib"
    exec ${pkgs.bun}/bin/bun ${qmdPkg}/lib/qmd/src/cli/qmd.ts "$@"
  '';
  qmdBin = "${qmdFixed}/bin/qmd";

  # Multilingual embedding model (Chinese + English)
  # Override default embeddinggemma-300M (English-only) for Chinese KB
  embedModel = "hf:Qwen/Qwen3-Embedding-0.6B-GGUF/Qwen3-Embedding-0.6B-Q8_0.gguf";

  knowledgeDir = "${config.home.homeDirectory}/knowledge";
  nixosConfigDir = "${config.home.homeDirectory}/nixos-config";
in
{
  options.custom.qmd = {
    enable = lib.mkEnableOption "QMD local search engine";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ qmdFixed ];

    # Declarative qmd config (read-only symlink to Nix store)
    # Changes to collections/contexts must go through this file.
    home.file.".config/qmd/index.yml".text = ''
      # QMD collections configuration (managed by NixOS)
      global_context: "Personal knowledge base and project documentation"

      collections:
        knowledge:
          path: ${knowledgeDir}
          pattern: "**/*.md"
          # Auto git pull before index refresh (eliminates sync lag window)
          update-cmd: "git -C ${knowledgeDir} pull --rebase --ff-only"
          context:
            "/raw/articles": "Source articles (blog posts, web clippings)"
            "/raw/papers": "Academic papers and research documents"
            "/raw/notes": "Personal notes and meeting transcripts"
            "/raw/transcripts": "Audio/video transcripts"
            "/wiki": "AI-generated wiki pages (summaries, concepts, indexes)"
            "/": "Knowledge base root"
        nixos-docs:
          path: ${nixosConfigDir}/docs
          pattern: "**/*.md"
          update-cmd: "git -C ${nixosConfigDir} pull --rebase --ff-only"
          context:
            "/desktop-1": "desktop-1 host-specific documentation"
            "/": "NixOS configuration architecture and decisions"
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
    # QMD_LLAMA_GPU=cuda: use CUDA GPU acceleration via node-llama-cpp prebuilt
    # binary. Requires /run/opengl-driver/lib in LD_LIBRARY_PATH (set in wrapper).
    systemd.user.services.qmd-mcp = {
      Unit = {
        Description = "QMD MCP HTTP server (localhost:8181)";
      };
      Service = {
        ExecStart = "${qmdBin} mcp --http --port 8181";
        Environment = [
          "QMD_EMBED_MODEL=${embedModel}"
          "QMD_LLAMA_GPU=cuda"
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
          "QMD_LLAMA_GPU=cuda"
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
  };
}
