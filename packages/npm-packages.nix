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
      version = "0.1.41";
      tarballHash = "sha256-DqOHVzCzwJwYDgSDPEm6o9sNrhldaixZz81VH1LOBoI=";
      npmDepsHash = "sha256-IRcZXghk2Pnj97XBn4K285Ponz+wvfXr+YhX8M0fJhY=";
      lockfile = ./npm/lockfiles/gh-axi.package-lock.json;
      description = "Agent ergonomic wrapper around GitHub CLI";
    };

    chrome-devtools-axi = mkNpmTool {
      pname = "chrome-devtools-axi";
      version = "0.1.43";
      tarballHash = "sha256-izGGOc1+CeXuTgm+/nxi4yRW9rTxfJ65HqxL9QWbpZk=";
      npmDepsHash = "sha256-npG04dresDaLEd2km4IB+d/K0OY45/3rD2gQje91Xdg=";
      lockfile = ./npm/lockfiles/chrome-devtools-axi.package-lock.json;
      description = "Agent interface for Chrome DevTools";
    };

    chrome-devtools-mcp = mkNpmTool {
      pname = "chrome-devtools-mcp";
      version = "1.11.0";
      tarballHash = "sha256-6fCrl62VFZJ8fZ8KPfvbnqSF0oENVy5KZOuEsZLIvww=";
      npmDepsHash = "sha256-PymD9Bads/Nigm6MRFQCHMViR7wkMD+rPv4stv9ql2I=";
      lockfile = ./npm/lockfiles/chrome-devtools-mcp.package-lock.json;
      description = "Official Chrome DevTools MCP server and CLI";
      homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
      license = lib.licenses.asl20;
    };

    lavish-axi = mkNpmTool {
      pname = "lavish-axi";
      version = "0.1.89";
      tarballHash = "sha256-knlkko0vP++57uO31iFN8ZLQeaQRsPj6wBYIyVtAYvg=";
      npmDepsHash = "sha256-up58jylvIeVTLeyXnNq/mECTXerM1n3ckH67Pvxm6GY=";
      lockfile = ./npm/lockfiles/lavish-axi.package-lock.json;
      description = "Agent interface for the Lavish editor";
    };

    tasks-axi = mkNpmTool {
      pname = "tasks-axi";
      version = "0.2.6";
      tarballHash = "sha256-kzQv5sga9RZpvYonP56ImjY0KISHc8yQe64fcak5Cdk=";
      npmDepsHash = "sha256-jdKni/L91nMAOQyynkDzf1kjFcTRhDs1NB8CmsHNsb8=";
      lockfile = ./npm/lockfiles/tasks-axi.package-lock.json;
      description = "Agent interface for task management";
    };

    quota-axi = mkNpmTool {
      pname = "quota-axi";
      version = "0.1.64";
      tarballHash = "sha256-RjuA9o4sWbylwal2Rp0t3UQPJmP6Tt/MNF5CUs2e/pc=";
      npmDepsHash = "sha256-YRTxJd42Vzatxxm1WrfyJBMSZ3CZighuE9dJ1IEuQ0E=";
      lockfile = ./npm/lockfiles/quota-axi.package-lock.json;
      description = "Agent interface for quota tracking";
    };
  };
}
