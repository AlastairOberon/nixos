{ ... }:

{
  networking = {
    # It is highly recommended to change this to something unique to easily 
    # identify this machine on your Wi-Fi network! (e.g., "nixos-server" or "homelab")
    hostName = "nixos"; 
    
    networkmanager = {
      enable = true;
      # Disable power saving to keep the Wi-Fi adapter at peak performance for low latency
      wifi.powersave = false;
      
      # Tell NetworkManager to defer to systemd-resolved for DNS handling
      dns = "systemd-resolved";

      # Enable MAC address randomization for Wi-Fi connections to improve privacy on public networks
      settings = {
        connection = {
          "wifi.cloned-mac-address" = "random";
        };
      };
    };

    # Set Cloudflare as the global upstream DNS provider (both IPv4 and IPv6).
    # The '#one.one.one.one' allows systemd-resolved to verify the TLS certificate.
    nameservers = [ 
      "1.1.1.1#one.one.one.one" 
      "1.0.0.1#one.one.one.one" 
      "2606:4700:4700::1111#one.one.one.one"
      "2606:4700:4700::1001#one.one.one.one"
    ];

    firewall = {
      enable = true; # This is true by default, but good to be explicit
      
      # Open the ports your containers are bound to. 
      # This allows other devices on your Wi-Fi to reach them.
      allowedTCPPorts = [ 8787 8096 7359 8181 ]; 
      
      # If any of your containers use UDP (like DNS or game servers), add them here:
      # allowedUDPPorts = [ 53 ]; 
    };
  };

  # Enable systemd-resolved for system-wide encrypted DNS
  services.resolved = {
    enable = true;
    
    # Set to "allow-downgrade" to prevent complete internet loss on networks/ISPs 
    # that do not support DNSSEC or use captive portals (e.g., public Wi-Fi).
    dnssec = "allow-downgrade"; 
    
    # Enable DNS over TLS to encrypt all system DNS queries
    dnsovertls = "true"; 
    
    # Force all local traffic to route through the secure upstream servers
    domains = [ "~." ]; 
    
    # Provide secure fallbacks just in case NetworkManager drops the primary
    fallbackDns = [ 
      "1.1.1.1#one.one.one.one" 
      "1.0.0.1#one.one.one.one" 
      "2606:4700:4700::1111#one.one.one.one"
      "2606:4700:4700::1001#one.one.one.one"
    ];
  };

  # Enable Avahi for mDNS/DNS-SD (Zero-configuration networking)
  # This allows you to access this machine as "nixos.local" and discover other local devices.
  services.avahi = {
    enable = true;
    nssmdns4 = true; # Enable NSS mDNS to resolve .local domains
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # Enable TCP BBR congestion control for better network throughput and lower latency,
  # especially beneficial on Wi-Fi connections.
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
}
