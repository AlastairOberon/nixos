{ pkgs, ... }:

{
  xdg.portal = {
    enable = true;
    
    # Add the GTK portal (which Zenity and Steam desperately want)
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];

    # Set default portal behaviors
    config.common.default = "*";
  };
}
