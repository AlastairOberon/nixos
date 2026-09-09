{ config, pkgs, inputs, ... }:

{
  # Generates the policies.json file where Zen can read it
  environment.etc."zen/policies/policies.json".text = builtins.toJSON {
    policies = {
      # --- Video Recommendation: "Disable all Firefox data collection" ---
      DisableTelemetry = true;
      DisableFirefoxStudies = true;

      # --- Video Recommendation: "Enable HTTPS only mode in all windows" ---
      HTTPSOnlyMode = "force_enabled";

      # Disable Pocket (Commonly recommended alongside disabling snippets)
      DisablePocket = true;
      
      # --- Custom Search Engine Configuration ---
      SearchEngines = {
        Default = "SearXNG";
        Add = [
          {
            Name = "SearXNG";
            URLTemplate = "http://localhost:8181/search?q={searchTerms}";
            Method = "GET";
            IconURL = "http://localhost:8181/favicon.ico";
            Alias = "@searxng";
            Description = "Self-hosted SearXNG instance";
          }
        ];
      };

      Preferences = {
        # --- Video Recommendation: "Set Firefox's privacy protections to strict" ---
        "browser.contentblocking.category" = { Value = "strict"; Status = "locked"; };
        
        # --- Video Recommendation: "Mark Firefox to delete cookies and site data when Firefox is closed" ---
        "network.cookie.lifetimePolicy" = { Value = 2; Status = "locked"; };
        "privacy.sanitize.sanitizeOnShutdown" = { Value = true; Status = "locked"; };

        # --- Video Recommendation: "Disable recommended extensions as you browse and disable recommended features" ---
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = { Value = false; Status = "locked"; };
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = { Value = false; Status = "locked"; };
        
        # --- Video Recommendation: "Make sure snippets are disabled" ---
        "browser.newtabpage.activity-stream.feeds.snippets" = { Value = false; Status = "locked"; };

        # --- Video Recommendation: "Make sure DNS over HTTPS is enabled" ---
        "network.trr.mode" = { Value = 2; Status = "locked"; };
        
        # --- Force Encrypted DNS Provider (Cloudflare) ---
        "network.trr.uri" = { Value = "https://cloudflare-dns.com/dns-query"; Status = "locked"; };
        
        # --- Video Recommendation: Website isolation using Fission ---
        "fission.autostart" = { Value = true; Status = "locked"; };

        # ==========================================
        # --- NEW: HARDWARE ACCELERATION & WAYLAND ---
        # ==========================================
        "gfx.webrender.all" = { Value = true; Status = "locked"; };
        "media.hardware-video-decoding.enabled" = { Value = true; Status = "locked"; };

        # ==========================================
        # --- NEW: GAMING PING PROTECTION ---
        # ==========================================
        # Stops the browser from pre-loading links in the background
        "network.prefetch-next" = { Value = false; Status = "locked"; };
        "network.dns.disablePrefetch" = { Value = true; Status = "locked"; };

        # ==========================================
        # --- NEW: MEMORY MANAGEMENT FOR DOCKER ---
        # ==========================================
        # Forces the browser to unload tabs when RAM gets tight
        "browser.tabs.unloadOnLowMemory" = { Value = true; Status = "locked"; };

        # ==========================================
        # --- NEW: ANTI-FINGERPRINTING ---
        # ==========================================
        # Enables the strict, Tor-based anti-fingerprinting engine
        "privacy.resistFingerprinting" = { Value = true; Status = "locked"; };
        
        # Spoofs canvas data if a site tries to fingerprint your graphics card
        "privacy.resistFingerprinting.randomDataOnCanvasExtract" = { Value = true; Status = "locked"; };
      };

      ExtensionSettings = {
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        
        # Bitwarden Password Manager
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          installation_mode = "force_installed";
        };

        # ProtonVPN 
        "vpn@proton.ch" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/proton-vpn-firefox-extension/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };

  environment.systemPackages = [
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # --- NEW: Force Native Wayland ---
  # This ensures Zen/Firefox never falls back to blurry XWayland
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
  };
}
