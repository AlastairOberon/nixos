{ pkgs, ... }:

{
    programs.thunar = {
        enable = true;
        plugins = with pkgs; [
            thunar-archive-plugin
            thunar-volman
        ];
    };
    
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # Compatibility wrapper so Thunar internal menu items calling exo-open launch Ghostty
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "exo-open" ''
      dir=""
      while [ $# -gt 0 ]; do
        case "$1" in
          --working-directory)
            dir="$2"
            shift 2
            ;;
          *)
            shift
            ;;
        esac
      done

      if [ -n "$dir" ]; then
        exec ${pkgs.ghostty}/bin/ghostty --working-directory="$dir"
      else
        exec ${pkgs.ghostty}/bin/ghostty
      fi
    '')
  ];
}
