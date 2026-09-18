{ pkgs, inputs, ... }:

{
  programs.yazi = {
    enable = true;
    # Fast, pre-compiled binary from official Nix cache (instant install on new machines):
    package = pkgs.yazi;
    # Bleeding-edge git main (compiles from source - uncomment if latest git features needed):
    # package = inputs.yazi.packages.${pkgs.stdenv.hostPlatform.system}.default;
    
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
