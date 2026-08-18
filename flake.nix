{
    description = "Alastair_FlakeConfiguration";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

        # External Application 1: Zen Browser
        zen-browser = {
            url = "github:youwen5/zen-browser-flake";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        
        # 🌟 External Plugin: Hyprglass
        hyprglass = {
            url = "github:hyprnux/hyprglass";
            flake = false; # Tell Nix this is just source code, not a Nix flake
        };

    };

    outputs = { self, nixpkgs, ... }@inputs: {
        nixosConfigurations = {
            nixos = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                {
                    _module.args = { inherit inputs; };
                }
                ./configuration.nix
                ];
            };
        };
    };
}
