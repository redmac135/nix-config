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
      version = "1.45.4";
      src = pkgs.fetchFromGitHub {
        owner = "kunchenguid";
        repo = "no-mistakes";
        rev = "v1.45.4";
        hash = "sha256-pfR60vack5oLItPfu4zDYYk76S8qhDOJP/uiudo7kVI=";
      };
      vendorHash = "sha256-NZOYxNYvt4192uqKBdKRxdgrKFvWx3585psdCnRdPSM=";
      subPackages = ["cmd/no-mistakes"];
      ldflags = [
        "-X github.com/kunchenguid/no-mistakes/internal/buildinfo.Version=v1.45.4"
        "-X github.com/kunchenguid/no-mistakes/internal/buildinfo.Commit=0c58eb71"
        "-X github.com/kunchenguid/no-mistakes/internal/buildinfo.Date=2026-08-04"
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
      version = "0.1.57";
      tarballHash = "sha256-Et4vDIWJ0YMbgOqGmJgFUPByOCueg2oOGL9UmUTCzV8=";
      npmDepsHash = "sha256-F2Y936Ka15e1BwLmd4md7Kfl0zEDwYD6ovcCG0cgui8=";
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
      version = "0.1.30";
      tarballHash = "sha256-XgcbfERvQVBdoeQe4BmBkAqM4chm2ELYf6qW9ssYzsU=";
      npmDepsHash = "sha256-NmDkzf0j20QPWc5i/ZZullNb38FmzZOQySXJDiDz+0E=";
      lockfile = ./firstmate/lockfiles/quota-axi.package-lock.json;
      description = "Agent interface for quota tracking";
    };
  };
}
