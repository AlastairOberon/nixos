{
    description = "Alastair_FlakeConfiguration";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

        # Zen Browser
        zen-browser = {
            url = "github:youwen5/zen-browser-flake";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        
        # HyprLandPlugin Hyprglass
        hyprglass = {
            url = "github:hyprnux/hyprglass";
            flake = false; # Tell Nix this is just source code, not a Nix flake
        };

        #Ad Free Spotiy
        spotx = {
            url = "github:SpotX-Official/SpotX-Nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        
        #yazi Bleeding Edge
        yazi.url = "github:sxyazi/yazi";

        #Home Manager
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        # Add Herdr
        herdr.url = "github:herdrdev/herdr";

        #Affinity
        affinity-nix = {
            url = "github:mrshmllow/affinity-nix";
            inputs.nixpkgs.follows = "nixpkgs"; 
        };

    };

    outputs = { self, nixpkgs, spotx, home-manager, ... }@inputs: {
        nixosConfigurations = {
            nixos = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = [
                {
                    _module.args = { inherit inputs; };
                }
                ./configuration.nix
                ./modules/flake/affinity.nix

                home-manager.nixosModules.home-manager
                    
                    # 2. Tell Home Manager to read your home.nix file
                    {
                        home-manager.useGlobalPkgs = true;
                        home-manager.useUserPackages = true;
                        home-manager.extraSpecialArgs = { inherit inputs; };
                        home-manager.users.alastair_oberon = import ./home.nix;
                    }
                ];
            };
        };
    };
}
