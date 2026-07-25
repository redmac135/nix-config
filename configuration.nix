{ config, lib, pkgs, ... }:

{
  wsl.enable = true;
  wsl.defaultUser = "ezhao";

  users.users.ezhao = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  system.stateVersion = "26.05";
}
