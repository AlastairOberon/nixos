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
    };

    # Set Cloudflare as the global upstream DNS provider.
    # The '#one.one.one.one' allows systemd-resolved to verify the TLS certificate.
    nameservers = [ 
      "1.1.1.1#one.one.one.one" 
      "1.0.0.1#one.one.one.one" 
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
    
    # Enable DNSSEC to ensure DNS records haven't been tampered with
    dnssec = "true"; 
    
    # Enable DNS over TLS to encrypt all system DNS queries
    dnsovertls = "true"; 
    
    # Force all local traffic to route through the secure upstream servers
    domains = [ "~." ]; 
    
    # Provide a secure fallback just in case NetworkManager drops the primary
    fallbackDns = [ 
      "1.1.1.1#one.one.one.one" 
      "1.0.0.1#one.one.one.one" 
    ];
  };
}
