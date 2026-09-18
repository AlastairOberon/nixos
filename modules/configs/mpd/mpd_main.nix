{ config, pkgs, ... }:

{
  xdg.configFile."mpd/mpd.conf".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/mpd/src/mpd.conf";

  # Ensure the MPD playlist directory exists
  home.file.".config/mpd/playlists/.keep".text = "";

  # Run MPD as a user systemd service so it accesses ~/Music and PipeWire natively
  systemd.user.services.mpd = {
    Unit = {
      Description = "Music Player Daemon";
      After = [ "network.target" "sound.target" "pipewire.service" ];
    };
    Service = {
      ExecStart = "${pkgs.mpd}/bin/mpd --no-daemon";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
