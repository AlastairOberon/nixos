{ pkgs, ... }:

{
  programs.yazi = {
    enable = true;
    
    # Declaratively fetch and install Yazi plugins
    plugins = {
      compress = pkgs.fetchFromGitHub {
        owner = "KKV9";
        repo = "compress.yazi";
        rev = "main";
        # We intentionally use a fake hash here so Nix will fail and give us the correct one
        sha256 = "sha256-9cdA8D/TtwHcLqrtoyIixA0YJmTs+c8FSNrjxp8CYI0="; 
      };
    };
  };
}
