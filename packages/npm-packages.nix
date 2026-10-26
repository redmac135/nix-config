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
      version = "0.1.44";
      tarballHash = "sha256-auUuNY6h1rHdpcK2yfgz5cwbWxanSny8R9kK5XZLKwg=";
      npmDepsHash = "sha256-yyIe+cp7IIDUMTxinzLk1RRNuOQAankeZxVAlVrAaGs=";
      lockfile = ./npm/lockfiles/gh-axi.package-lock.json;
      description = "Agent ergonomic wrapper around GitHub CLI";
    };

    chrome-devtools-axi = mkNpmTool {
      pname = "chrome-devtools-axi";
      version = "0.1.45";
      tarballHash = "sha256-DIXYlxZWbUrKS40Jf2CCph3h8tuNnjM+KhxXSRIQ7p8=";
      npmDepsHash = "sha256-aCbo6Hfzq/4ca4hdCt12UOPvt/3w/IAnw+QJzzYH6eo=";
      lockfile = ./npm/lockfiles/chrome-devtools-axi.package-lock.json;
      description = "Agent interface for Chrome DevTools";
    };

    chrome-devtools-mcp = mkNpmTool {
      pname = "chrome-devtools-mcp";
      version = "1.12.0";
      tarballHash = "sha256-Sq3jFnw+eBx5fWEJ7WA6DKW4yzY6KJ4uqsqpsMXSo2A=";
      npmDepsHash = "sha256-vukJEjQB9jYvIEVwu4VYGw80I/CcniWW/+UeZTO+hr0=";
      lockfile = ./npm/lockfiles/chrome-devtools-mcp.package-lock.json;
      description = "Official Chrome DevTools MCP server and CLI";
      homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
      license = lib.licenses.asl20;
    };

    lavish-axi = mkNpmTool {
      pname = "lavish-axi";
      version = "0.1.93";
      tarballHash = "sha256-lPvtSyIzBjEOg2wd8q3VtUbCzGrdSFhqguGBXIBAzU0=";
      npmDepsHash = "sha256-W4NWTBBksgBCO5fAmNBwUCaZX1np0iRm0tIZlB8POow=";
      lockfile = ./npm/lockfiles/lavish-axi.package-lock.json;
      description = "Agent interface for the Lavish editor";
    };

    tasks-axi = mkNpmTool {
      pname = "tasks-axi";
      version = "0.2.6";
      tarballHash = "sha256-kzQv5sga9RZpvYonP56ImjY0KISHc8yQe64fcak5Cdk=";
      npmDepsHash = "sha256-UL/FvCC25HJWKlTdWpGtKPlUqBOkmRVKXgUlwk6buE8=";
      lockfile = ./npm/lockfiles/tasks-axi.package-lock.json;
      description = "Agent interface for task management";
    };

    quota-axi = mkNpmTool {
      pname = "quota-axi";
      version = "0.1.68";
      tarballHash = "sha256-zV5JeXxBqgyQzWe2BRpGAYdc1G0Kp2ahc3nfhm0XW9c=";
      npmDepsHash = "sha256-ow/PqhA1CrBf8LoIx8s/ikuOqCKu7ZGIR+/ar7h2MZU=";
      lockfile = ./npm/lockfiles/quota-axi.package-lock.json;
      description = "Agent interface for quota tracking";
    };
  };
}
