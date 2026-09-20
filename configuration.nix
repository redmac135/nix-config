{
  config,
  lib,
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfreePredicate = pkg: lib.getName pkg == "copilot-language-server";

  wsl.enable = true;
  wsl.defaultUser = "ezhao";

  users.users.ezhao = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
      "dialout"
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGwaOLmlmVgJwwxG/ColvYAL/D0ZehXqnFiPgV/DEwzw ezhao@onhandwsl"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPYWG5w0FgJtRaRbwU6VI441YHvY1UIkMPWTaMksr/9s ezhao@pancakewsl"
    ];
  };

  # usbipd-wsl invokes modprobe when attaching USB devices from Windows.
  environment.systemPackages = [pkgs.kmod];

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

  # NixOS owns the Cloudflare Tunnel service; `cloudflared service install`
  # cannot write /etc/systemd/system on an immutable NixOS system.
  systemd.services.htn26-cloudflared = {
    description = "HTN26 Cloudflare Tunnel";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target"];
    after = ["network-online.target"];
    serviceConfig = {
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel run --token $CLOUDFLARED_TUNNEL_TOKEN";
      EnvironmentFile = "-/var/lib/cloudflared/htn26.env";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/cloudflared 0750 root root -"
  ];

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
