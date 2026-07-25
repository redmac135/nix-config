{
  config,
  lib,
  pkgs,
  ...
}:
{
  wsl.enable = true;
  wsl.defaultUser = "ezhao";

  users.users.ezhao = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    shell = pkgs.zsh;
  };

  # Enable Docker daemon at system level
  virtualisation.docker.enable = true;

  # mirror Arch wsl fix: https://gitlab.archlinux.org/archlinux/archlinux-wsl/-/work_items/16
  systemd.services."getty@tty1".enable = false;

  programs.zsh.enable = true;

  system.stateVersion = "26.05";
}
