{ pkgs, inputs, ... }:

{
  environment.systemPackages = [
    # Terminal AI agent
    pkgs.aider-chat
  ];

  programs.firejail = {
    enable = true;

    wrappedBinaries = {
      herdr = {
        executable = "${inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/herdr";

        profile = pkgs.writeText "herdr.profile" ''
          # 1. Allow write access and git commits in the NixOS config folder
          read-write /etc/nixos

          # 2. External & removable drive mounts
          blacklist /mnt
          blacklist /media
          blacklist /run/media

          # 3. Personal user directories
          blacklist ~/Downloads
          blacklist ~/Pictures
          blacklist ~/Documents
          blacklist ~/Videos
          blacklist ~/Music
          blacklist ~/Desktop

          # 4. Sensitive security credentials & keys
          blacklist ~/.ssh
          blacklist ~/.gnupg
          blacklist ~/.env
          blacklist ~/.local/share/keyrings

          # 5. Browser profiles & passwords
          blacklist ~/.zen
          blacklist ~/.mozilla
          blacklist ~/.config/Bitwarden
        '';
      };
    };
  };
}
