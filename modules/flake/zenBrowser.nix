{ config, pkgs, ... }:

{
  # Generates the policies.json file where Zen can read it
  environment.etc."zen/policies/policies.json".text = builtins.toJSON {
    policies = {
      ExtensionSettings = {
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        
        # Bitwarden Password Manager
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };

  # Fallback: Some Firefox forks still hardcode the upstream policies path.
  # Uncomment the block below if Zen ignores the /etc/zen/ path above.
  /*
  environment.etc."firefox/policies/policies.json".text = builtins.toJSON {
    policies = { ... same as above ... };
  };
  */
}
