{
  nixConfig = {
    extra-substituters = ["https://cache.numtide.com"];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

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
    systems = [
      "aarch64-linux"
      "x86_64-linux"
    ];

    mkNixos = system: osName:
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          nixos-wsl.nixosModules.default
          ./configuration.nix
          {
            networking.hostName = osName;
            system.nixos.distroName = osName;
          }

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
                    treehouse =
                      treehouse.packages.${prev.stdenv.hostPlatform.system}
                      // {
                        # Upstream's TestPruneSkipsUnmergedCommit is flaky in
                        # sandboxed closure builds; its package is tested upstream.
                        default = treehouse.packages.${prev.stdenv.hostPlatform.system}.default.overrideAttrs {
                          doCheck = false;
                        };
                      };
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
      onhandwsl = mkNixos "aarch64-linux" "onhandwsl";
      pancakewsl = mkNixos "x86_64-linux" "pancakewsl";
    };

    devShells = nixpkgs.lib.genAttrs systems (system: {
      tauri = let
        pkgs = import nixpkgs {inherit system;};
      in
        pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            pkg-config
            wrapGAppsHook4
          ];

          buildInputs = with pkgs; [
            webkitgtk_4_1
            librsvg
            gst_all_1.gst-plugins-base
          ];
        };
    });
  };
}
