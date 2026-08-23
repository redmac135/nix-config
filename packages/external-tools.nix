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
    npmName ? pname,
    homepage ? "https://github.com/kunchenguid/${pname}",
    nodejs ? pkgs.nodejs,
    npmDepsFetcherVersion ? 1,
  }:
    pkgs.buildNpmPackage {
      inherit pname version nodejs npmDepsFetcherVersion;
      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/${npmName}/-/${pname}-${version}.tgz";
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
        inherit homepage;
        license = lib.licenses.mit;
      };
    };
in {
  firstmate = {
    no-mistakes = pkgs.buildGoModule {
      pname = "no-mistakes";
      version = "1.53.0";
      src = pkgs.fetchFromGitHub {
        owner = "kunchenguid";
        repo = "no-mistakes";
        rev = "f627beb7ffa8aceee353fb1deb88f40ae8611ad6";
        hash = "sha256-6+SrbK4Vz95RTpH3BH+ASPPXuMEIHAX80nqrYaKwlzQ=";
      };
      vendorHash = "sha256-NZOYxNYvt4192uqKBdKRxdgrKFvWx3585psdCnRdPSM=";
      subPackages = ["cmd/no-mistakes"];
      ldflags = [
        "-X github.com/kunchenguid/no-mistakes/internal/buildinfo.Version=v1.53.0"
        "-X github.com/kunchenguid/no-mistakes/internal/buildinfo.Commit=f627beb7"
        "-X github.com/kunchenguid/no-mistakes/internal/buildinfo.Date=2026-08-16"
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
      version = "0.1.29";
      tarballHash = "sha256-2GMZ59vDc4LCdWBHkRT3hKgqnJtHl4af/wGUhQikw20=";
      npmDepsHash = "sha256-e7qHEr2wTfDmTcnwf8zQBIcmhDA1bk1O9LdHGt+Znac=";
      lockfile = ./firstmate/lockfiles/gh-axi.package-lock.json;
      description = "Agent ergonomic wrapper around GitHub CLI";
    };

    chrome-devtools-axi = mkNpmTool {
      pname = "chrome-devtools-axi";
      version = "0.1.28";
      tarballHash = "sha256-9KQdHeAaA/g1yZ1bBN+oc4oURU//PMkB+UUsyTgoqfQ=";
      npmDepsHash = "sha256-r6u/i9BQv10Prt9/BSsc6fqxl4xTLxDW9KgZphcukAw=";
      lockfile = ./firstmate/lockfiles/chrome-devtools-axi.package-lock.json;
      description = "Agent interface for Chrome DevTools";
    };

    lavish-axi = mkNpmTool {
      pname = "lavish-axi";
      version = "0.1.45";
      tarballHash = "sha256-fD/nXuEyZMjHzYQDtI2Xle4Zl+0DN8i+GsXAnWPR7xQ=";
      npmDepsHash = "sha256-8MHo9+GqLBJuYEz3nBd6e00nL3oqK75SjY/XxQ+qFDg=";
      lockfile = ./firstmate/lockfiles/lavish-axi.package-lock.json;
      description = "Agent interface for the Lavish editor";
    };

    tasks-axi = mkNpmTool {
      pname = "tasks-axi";
      version = "0.2.4";
      tarballHash = "sha256-hujgVLbREGAe42U6l+P3zGxJ6tLD6V5BGie8YokRpcw=";
      npmDepsHash = "sha256-4kbA5woI+e4AGpdDAwZSmlXveFgywGnbZzGo4mntm74=";
      lockfile = ./firstmate/lockfiles/tasks-axi.package-lock.json;
      description = "Agent interface for task management";
    };

    quota-axi = mkNpmTool {
      pname = "quota-axi";
      version = "0.1.17";
      tarballHash = "sha256-gfH3C7n+OjX4eBoRZsfDyQnfwp8bXOr9tykVxmYkyzA=";
      npmDepsHash = "sha256-+qc5TG/sWa3ybwZywi0+UhXd7E2VLWE3igfRnYfZbtg=";
      lockfile = ./firstmate/lockfiles/quota-axi.package-lock.json;
      description = "Agent interface for quota tracking";
    };
  };

  pi-web = mkNpmTool {
    pname = "pi-web";
    version = "1.202608.1";
    npmName = "@jmfederico/pi-web";
    tarballHash = "sha256-6kgJ3wOJ07M5cpWeiFy9Hw3KvOoJH6qIBGRXvkJiHYc=";
    npmDepsHash = "sha256-7pqFDJE3cSKn4n6wWvHS+XlEaGSrAb2g+1ph5Vry55o=";
    # pi-coding-agent ships an npm-shrinkwrap whose nested dev deps are resolved
    # from packuments during `npm ci`, so the dependency cache must include
    # packuments too (npmDepsFetcherVersion = 2), not just tarballs.
    npmDepsFetcherVersion = 2;
    lockfile = ./pi-web/lockfiles/pi-web.package-lock.json;
    description = "Web UI for persistent Pi Coding Agent sessions in real workspaces";
    homepage = "https://pi-web.dev/";
    # node-pty ships no linux prebuilds, so npm rebuild compiles its native
    # binding against the nodejs_22 headers (node-gyp; python/gcc from stdenv).
    nodejs = pkgs.nodejs_22;
  };
}
