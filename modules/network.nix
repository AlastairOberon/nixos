{ pkgs, lib, ... }:

{
  # ---------------------------------------------------------
  # Host Networking
  # ---------------------------------------------------------
  networking = {
    # Default system and network identifier (overrideable in configuration.nix)
    hostName = lib.mkDefault "memosyne";

    networkmanager = {
      enable = true;
      # Disable power saving to keep Wi-Fi adapter latency low
      wifi.powersave = false;

      # Let systemd-resolved manage DNS
      dns = "systemd-resolved";

      # Enable MAC address randomization for Wi-Fi privacy
      settings = {
        connection = {
          "wifi.cloned-mac-address" = "random";
        };
      };
    };

    # Fallback DNS servers if systemd-resolved cannot reach configured servers
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];

    firewall = {
      enable = true;

      # Open container web UI ports to your local network
      allowedTCPPorts = [
        8787
        8096
        7359
        8181
        8090
        7860
      ];
    };
  };

  # ---------------------------------------------------------
  # DNS Resolution (systemd-resolved with DoT)
  # ---------------------------------------------------------
  services.resolved = {
    enable = true;

    settings = {
      Resolve = {
        DNSSEC = "allow-downgrade";
        DNSOverTLS = "true";
        Domains = [ "~." ];
        DNS = [
          "1.1.1.1#one.one.one.one"
          "1.0.0.1#one.one.one.one"
          "2606:4700:4700::1111#one.one.one.one"
          "2606:4700:4700::1001#one.one.one.one"
        ];
        FallbackDNS = [
          "1.1.1.1#one.one.one.one"
          "1.0.0.1#one.one.one.one"
          "2606:4700:4700::1111#one.one.one.one"
          "2606:4700:4700::1001#one.one.one.one"
        ];
      };
    };
  };

  # ---------------------------------------------------------
  # Local Service Discovery (mDNS)
  # ---------------------------------------------------------
  services.avahi = {
    enable = true;
    nssmdns4 = true; # Resolves .local hostnames
    # Automatically opens port 5353 in the firewall for Avahi
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # ---------------------------------------------------------
  # Kernel & Network Performance (TCP BBR)
  # ---------------------------------------------------------
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
}
