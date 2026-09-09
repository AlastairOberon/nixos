{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    cantarell-fonts
    
    atkinson-hyperlegible
    
    # Nerd Fonts Collection
    nerd-fonts.aurulent-sans-mono
    nerd-fonts.code-new-roman
    nerd-fonts.comic-shanns-mono
    nerd-fonts.commit-mono
    nerd-fonts.droid-sans-mono
    nerd-fonts.fira-code
    nerd-fonts.geist-mono
    nerd-fonts.hasklug
    nerd-fonts.hurmit
    nerd-fonts.monaspace
    nerd-fonts.open-dyslexic
    nerd-fonts.overpass
    nerd-fonts."_0xproto"
    nerd-fonts.iosevka
    nerd-fonts.jetbrains-mono
    nerd-fonts.liberation
    nerd-fonts.meslo-lg
    nerd-fonts.mononoki
    nerd-fonts.roboto-mono
    nerd-fonts.sauce-code-pro
    nerd-fonts.space-mono
    nerd-fonts.ubuntu
    nerd-fonts.victor-mono
    nerd-fonts.zed-mono
    nerd-fonts.monofur
  ];
}
