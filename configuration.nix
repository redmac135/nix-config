{
  config,
  lib,
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    lib.getName pkg == "copilot-language-server";

  wsl.enable = true;
  wsl.defaultUser = "ezhao";

  users.users.ezhao = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
    ];
  };

  # Enable Docker daemon at system level
  virtualisation.docker.enable = true;

  services.openssh = {
    enable = true;

    settings = {
      PubkeyAuthentication = true;
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AuthenticationMethods = "publickey";
      PermitRootLogin = "no";
    };
  };

  services.tailscale.enable = true;

  networking.firewall.trustedInterfaces = ["tailscale0"];

  # mirror Arch wsl fix: https://gitlab.archlinux.org/archlinux/archlinux-wsl/-/work_items/16
  systemd.services."getty@tty1".enable = false;

  programs.zsh.enable = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  system.stateVersion = "26.05";
}
