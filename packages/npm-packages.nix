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
      version = "0.1.51";
      tarballHash = "sha256-/umDcRd02PpQ7OyQpRqoAyU4ZIxod/yxxE172XFtVMI=";
      npmDepsHash = "sha256-zu1BgfqZHDlbJg+vjWAC+ftn9EXdLGavw62jClYxfLU=";
      lockfile = ./npm/lockfiles/gh-axi.package-lock.json;
      description = "Agent ergonomic wrapper around GitHub CLI";
    };

    chrome-devtools-axi = mkNpmTool {
      pname = "chrome-devtools-axi";
      version = "0.1.46";
      tarballHash = "sha256-YhP9z87gIt3J13LGJNPAMShzELeFXdg9K9rfoOm5DfE=";
      npmDepsHash = "sha256-IEgHVeNHASArkiL1Pi0kftTsqRfgI7PE/u+b+BN92AQ=";
      lockfile = ./npm/lockfiles/chrome-devtools-axi.package-lock.json;
      description = "Agent interface for Chrome DevTools";
    };

    chrome-devtools-mcp = mkNpmTool {
      pname = "chrome-devtools-mcp";
      version = "1.13.0";
      tarballHash = "sha256-kVjEtKh5LLUirkb3buqpSRzgRhajrpcimhYnfgKkrqQ=";
      npmDepsHash = "sha256-wyl5lxdhjqpmhed7B4xOEHKXqddaJ2vvb5evXCSbx6U=";
      lockfile = ./npm/lockfiles/chrome-devtools-mcp.package-lock.json;
      description = "Official Chrome DevTools MCP server and CLI";
      homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
      license = lib.licenses.asl20;
    };

    lavish-axi = mkNpmTool {
      pname = "lavish-axi";
      version = "0.1.96";
      tarballHash = "sha256-4Q1X1LIkerZxSDWJsi8jBf6d7NmLq+TURqzDLtTm5wI=";
      npmDepsHash = "sha256-ip3PpwTx6nGC1aZlfaFkRwjhaNxTa3UaVAFHdc9/5+g=";
      lockfile = ./npm/lockfiles/lavish-axi.package-lock.json;
      description = "Agent interface for the Lavish editor";
    };

    tasks-axi = mkNpmTool {
      pname = "tasks-axi";
      version = "0.2.6";
      tarballHash = "sha256-kzQv5sga9RZpvYonP56ImjY0KISHc8yQe64fcak5Cdk=";
      npmDepsHash = "sha256-AO8fjH7OMQnaAUFoEy0Q1P+OOU90KsdWm8CTYoUeJnU=";
      lockfile = ./npm/lockfiles/tasks-axi.package-lock.json;
      description = "Agent interface for task management";
    };

    quota-axi = mkNpmTool {
      pname = "quota-axi";
      version = "0.1.69";
      tarballHash = "sha256-1pSKI20ggK811yHtFGBViHpZDj3yP/a7lmVO6zyiaPU=";
      npmDepsHash = "sha256-v1jXdUZSNXwCbN95EQOwiNhVGfd/JOnsHDRXfW3ba3c=";
      lockfile = ./npm/lockfiles/quota-axi.package-lock.json;
      description = "Agent interface for quota tracking";
    };
  };
}
