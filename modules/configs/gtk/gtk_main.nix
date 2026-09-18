{ config, pkgs, ... }:

{
  xdg.configFile."gtk-3.0/settings.ini".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/gtk/src/gtk-3.0/settings.ini";
  xdg.configFile."gtk-3.0/gtk.css".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/gtk/src/gtk-3.0/gtk.css";
  xdg.configFile."gtk-3.0/colors.css".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/gtk/src/gtk-3.0/colors.css";
  xdg.configFile."gtk-3.0/bookmarks".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/gtk/src/gtk-3.0/bookmarks";

  xdg.configFile."gtk-4.0/settings.ini".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/gtk/src/gtk-4.0/settings.ini";
  xdg.configFile."gtk-4.0/colors.css".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.path}/modules/configs/gtk/src/gtk-4.0/colors.css";
}
