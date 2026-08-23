{
  config,
  lib,
  pkgs,
  ...
}: {
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

  services.tailscale.enable = true;

  # mirror Arch wsl fix: https://gitlab.archlinux.org/archlinux/archlinux-wsl/-/work_items/16
  systemd.services."getty@tty1".enable = false;

  programs.zsh.enable = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    extra-substituters = ["https://cache.numtide.com"];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  system.stateVersion = "26.05";
}
