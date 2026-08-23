{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    llm-agents.url = "github:numtide/llm-agents.nix";

    treehouse.url = "github:kunchenguid/treehouse";
    treehouse.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-wsl,
    home-manager,
    llm-agents,
    treehouse,
    ...
  }: let
    mkNixos = system:
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          nixos-wsl.nixosModules.default
          ./configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ezhao = import ./home.nix;
          }

          {
            nixpkgs.overlays = [
              (
                final: prev:
                  {
                    llmAgents = llm-agents.packages.${prev.stdenv.hostPlatform.system};
                    treehouse = treehouse.packages.${prev.stdenv.hostPlatform.system};
                  }
                  // import ./packages/external-tools.nix {
                    pkgs = final;
                    inherit (final) lib;
                  }
              )
            ];
          }
        ];
      };
  in {
    nixosConfigurations = {
      surface = mkNixos "aarch64-linux";
      desktop = mkNixos "x86_64-linux";
    };
  };
}
