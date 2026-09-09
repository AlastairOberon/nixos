{ pkgs, ... }:

{
  home.packages = [ pkgs.vdirsyncer ];

  # Maps the raw text file directly to ~/.config/vdirsyncer/config
  xdg.configFile."vdirsyncer/config".source = ./src/config;

  # Native systemd user service for background syncing
  systemd.user.services.vdirsyncer = {
    Unit = {
      Description = "Synchronize CalDAV calendars";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.vdirsyncer}/bin/vdirsyncer sync";
    };
  };

  systemd.user.timers.vdirsyncer = {
    Unit = {
      Description = "Timer for vdirsyncer";
    };
    Timer = {
      OnBootSec = "5m";
      OnUnitActiveSec = "15m";
      Unit = "vdirsyncer.service";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
