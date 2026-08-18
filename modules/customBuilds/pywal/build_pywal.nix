{ pkgs, ... }:

pkgs.pywal.overrideAttrs (oldAttrs: {
    propagatedBuildInputs = (oldAttrs.propagatedBuildInputs or []) ++ [ 
        pkgs.python3Packages.haishoku 
    ];
})
