{
  pkgs,
  lib,
}: let
  mkNpmTool = {
    pname,
    version,
    tarballHash,
    npmDepsHash,
    lockfile,
    description,
  }:
    pkgs.buildNpmPackage {
      inherit pname version;
      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
        hash = tarballHash;
      };
      npmDepsHash = npmDepsHash;
      # The published tarball already ships a prebuilt dist/, so there is no
      # build step. The vendored package-lock.json pins the dependency tree;
      # prepack/prepare would only rebuild dist/ from source we do not ship.
      postPatch = ''
        cp ${lockfile} package-lock.json
        ${lib.getExe pkgs.jq} 'del(.scripts.prepare, .scripts.prepack)' package.json > package.json.tmp
        mv package.json.tmp package.json
      '';
      dontNpmBuild = true;
      meta = {
        description = description;
        homepage = "https://github.com/kunchenguid/${pname}";
        license = lib.licenses.mit;
      };
    };
in {
  firstmate = {
    no-mistakes = pkgs.buildGoModule {
      pname = "no-mistakes";
      version = "1.75.2";
      src = pkgs.fetchFromGitHub {
        owner = "kunchenguid";
        repo = "no-mistakes";
        rev = "v1.75.2";
        hash = "sha256-57JRCgx08AtYDPBrMpIXWTtNyhrP/+/BIYNKcSjIthU=";
      };
      vendorHash = "sha256-NZOYxNYvt4192uqKBdKRxdgrKFvWx3585psdCnRdPSM=";
      subPackages = ["cmd/no-mistakes"];
      ldflags = [
        "-X github.com/kunchenguid/no-mistakes/internal/buildinfo.Version=v1.75.2"
        "-X github.com/kunchenguid/no-mistakes/internal/buildinfo.Commit=4debd429"
        "-X github.com/kunchenguid/no-mistakes/internal/buildinfo.Date=2026-09-14"
        "-X github.com/kunchenguid/no-mistakes/internal/buildinfo.TelemetryHost=https://a.kunchenguid.com"
        "-X github.com/kunchenguid/no-mistakes/internal/buildinfo.TelemetryWebsiteID=f959e889-92f5-4121-8a1f-571b10861198"
      ];
      meta = {
        description = "Local Git proxy that validates code before pushing";
        homepage = "https://github.com/kunchenguid/no-mistakes";
        license = lib.licenses.mit;
      };
    };

    gh-axi = mkNpmTool {
      pname = "gh-axi";
      version = "0.1.37";
      tarballHash = "sha256-AAN1NLf1F3OsFDkJ4ccncP5I+CVLkWFEl8gFk1LUA9s=";
      npmDepsHash = "sha256-xZRe1uoR/BWwrQN/gNMLyJcrggwz01BfqjGO8ltuxSE=";
      lockfile = ./firstmate/lockfiles/gh-axi.package-lock.json;
      description = "Agent ergonomic wrapper around GitHub CLI";
    };

    chrome-devtools-axi = mkNpmTool {
      pname = "chrome-devtools-axi";
      version = "0.1.39";
      tarballHash = "sha256-J+d4t3ovNEPqUIlr4OMLyPdNXVEwCxvXKR09f8KkrZk=";
      npmDepsHash = "sha256-F8OJgUwE9Da0dTrcrJJzxds1gqgR1mp9wfO+/lFm0xo=";
      lockfile = ./firstmate/lockfiles/chrome-devtools-axi.package-lock.json;
      description = "Agent interface for Chrome DevTools";
    };

    lavish-axi = mkNpmTool {
      pname = "lavish-axi";
      version = "0.1.86";
      tarballHash = "sha256-xbOVj5/OkxBeFwEnJqCC11RIIXuNcy9iVrTLjM9D2qs=";
      npmDepsHash = "sha256-YvM/JXQ2GL9JWTx+c/B3WRv+SHTkBUT1V5FNovYD0Uw=";
      lockfile = ./firstmate/lockfiles/lavish-axi.package-lock.json;
      description = "Agent interface for the Lavish editor";
    };

    tasks-axi = mkNpmTool {
      pname = "tasks-axi";
      version = "0.2.6";
      tarballHash = "sha256-kzQv5sga9RZpvYonP56ImjY0KISHc8yQe64fcak5Cdk=";
      npmDepsHash = "sha256-q3KzjmIyNmg2rtLLhNWb1ClodvYdDch+HjcIiG0tIxU=";
      lockfile = ./firstmate/lockfiles/tasks-axi.package-lock.json;
      description = "Agent interface for task management";
    };

    quota-axi = mkNpmTool {
      pname = "quota-axi";
      version = "0.1.60";
      tarballHash = "sha256-xPteyWKMeLJGhjYwApI0KCDTPI8cTwcOR7TjpayVnkc=";
      npmDepsHash = "sha256-C1kY9AUjlJ3zxCdPuNAl5p9unwN2yrxXEjy6vGOq+IM=";
      lockfile = ./firstmate/lockfiles/quota-axi.package-lock.json;
      description = "Agent interface for quota tracking";
    };
  };
}
