{ ... }:

{
  imports = [
    # =========================================================================
    # CORE DESKTOP & FAST APPS (Cached / Instant install)
    # =========================================================================
    ./docker.nix
    ./thunar.nix
    ./zenBrowser.nix
    ./alcom.nix
    ./yazi.nix

    # =========================================================================
    # HEAVY FLAKE PACKAGES (Uncomment to enable on this PC, or move to holding.nix)
    # =========================================================================
    ./affinity.nix # Affinity Creative Suite (Currently parked in holding.nix)
    ./herdr.nix # Herdr AI Agent (Compiles from source: Zig, C, Ghostty VT)
    ./unityHub.nix # Unity Hub (Heavy proprietary Electron engine manager)
    ./ollama.nix # Ollama Local LLM & Embedding Daemon (nomic-embed-text)


    # =========================================================================
    # OPTIONAL CONTAINER COMPOSE SERVICES (Uncomment to enable)
    # =========================================================================
    # ./podmanRunningServices/searxng_compose.nix
    # ./podmanRunningServices/sillytavern_compose.nix
  ];
}
