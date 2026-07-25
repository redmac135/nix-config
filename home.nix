{ config, pkgs, ... }:

{
  home.username = "ezhao";
  home.homeDirectory = "/home/ezhao";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    git
    neovim
  ];

  xdg.configFile."nvim".source = ./nvim;

  programs.home-manager.enable = true;
}
