{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-wsl,
    home-manager,
    ...
  }: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          nixos-wsl.nixosModules.default
          ./configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ezhao = import ./home.nix;
          }
        ];
      };
    };
  };
}
