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
    license ? lib.licenses.mit,
    homepage ? "https://github.com/kunchenguid/${pname}",
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
        inherit homepage license;
      };
    };
in {
  npmPkgs = {
    gh-axi = mkNpmTool {
      pname = "gh-axi";
      version = "0.1.43";
      tarballHash = "sha256-lIH0ly04P9awMX2b855+kpiu5RyFOQ0p0eDgJ8ZVFP0=";
      npmDepsHash = "sha256-K9D67ZbVkLTv3W8ANN5Y/SKfR5/eO6gHx6kuF6WxICA=";
      lockfile = ./npm/lockfiles/gh-axi.package-lock.json;
      description = "Agent ergonomic wrapper around GitHub CLI";
    };

    chrome-devtools-axi = mkNpmTool {
      pname = "chrome-devtools-axi";
      version = "0.1.44";
      tarballHash = "sha256-q4kheZmuBM1ECxszeLuOawPiffC1Y8qw94tXbyP+kDc=";
      npmDepsHash = "sha256-1lMotku66p4yrZ3s60+oOg9hyjaFv0BBmZPudOyVQvg=";
      lockfile = ./npm/lockfiles/chrome-devtools-axi.package-lock.json;
      description = "Agent interface for Chrome DevTools";
    };

    chrome-devtools-mcp = mkNpmTool {
      pname = "chrome-devtools-mcp";
      version = "1.12.0";
      tarballHash = "sha256-Sq3jFnw+eBx5fWEJ7WA6DKW4yzY6KJ4uqsqpsMXSo2A=";
      npmDepsHash = "sha256-pGR8WTeNkXlwAPy/zFlbSryS4kCAaN0Q63vZteJc75k=";
      lockfile = ./npm/lockfiles/chrome-devtools-mcp.package-lock.json;
      description = "Official Chrome DevTools MCP server and CLI";
      homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
      license = lib.licenses.asl20;
    };

    lavish-axi = mkNpmTool {
      pname = "lavish-axi";
      version = "0.1.90";
      tarballHash = "sha256-m+2dcLX6W90VFKJJN9Lg+b4ExDw5YTIcxrfmup5/kr4=";
      npmDepsHash = "sha256-egvL9F1STORpXAlL0Qxr7srCO7mPTu4TxEH4Pd9GEg4=";
      lockfile = ./npm/lockfiles/lavish-axi.package-lock.json;
      description = "Agent interface for the Lavish editor";
    };

    tasks-axi = mkNpmTool {
      pname = "tasks-axi";
      version = "0.2.6";
      tarballHash = "sha256-kzQv5sga9RZpvYonP56ImjY0KISHc8yQe64fcak5Cdk=";
      npmDepsHash = "sha256-xn1OCPlWMULbUGDmBDK4IDT0Y1/nDDc8Pn9MzYhSsuQ=";
      lockfile = ./npm/lockfiles/tasks-axi.package-lock.json;
      description = "Agent interface for task management";
    };

    quota-axi = mkNpmTool {
      pname = "quota-axi";
      version = "0.1.66";
      tarballHash = "sha256-wclQQaf5BUiALWfUihHemNx4MNGOesaIViYeCO/UU1g=";
      npmDepsHash = "sha256-0XApi7T/NSfMvggh7zxwoHrbnmecMVk5I34XU9QUUbY=";
      lockfile = ./npm/lockfiles/quota-axi.package-lock.json;
      description = "Agent interface for quota tracking";
    };
  };
}
