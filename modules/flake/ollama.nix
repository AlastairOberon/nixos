{ pkgs, ... }:

{
  # =========================================================================
  # Ollama Local LLM & Embedding Daemon
  # =========================================================================
  services.ollama = {
    enable = true;

    # Hardware acceleration package selection (NixOS 26.11 / unstable):
    # - pkgs.ollama-vulkan: GPU acceleration via Vulkan. Pre-cached in Hydra (instant download).
    # - pkgs.ollama-cuda: Full NVIDIA CUDA acceleration on your RTX 3060 Mobile.
    #                     Requires local compilation of the Ollama wrapper on first build.
    # - pkgs.ollama: CPU-only pre-cached build. Very lightweight and sufficient for nomic-embed-text.
    package = pkgs.ollama-vulkan;

    # Host & port binding
    host = "127.0.0.1";
    port = 11434;

    # Automatically download models via systemd `ollama-model-loader.service` once ollama starts
    loadModels = [
      "nomic-embed-text"
    ];

    # Optional environment variables
    environmentVariables = {
      # Keep loaded models in memory for 15 minutes after last request
      OLLAMA_KEEP_ALIVE = "15m";
    };
  };
}
