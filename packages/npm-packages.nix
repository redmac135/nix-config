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
      npmDepsHash = "sha256-xGSMDHpiakamsgqRqatmr8a1DpzSh6mraZ0XqOznCYo=";
      lockfile = ./npm/lockfiles/gh-axi.package-lock.json;
      description = "Agent ergonomic wrapper around GitHub CLI";
    };

    chrome-devtools-axi = mkNpmTool {
      pname = "chrome-devtools-axi";
      version = "0.1.44";
      tarballHash = "sha256-q4kheZmuBM1ECxszeLuOawPiffC1Y8qw94tXbyP+kDc=";
      npmDepsHash = "sha256-aMTmrGomu9jvwlX3RyHD5nWGrmJI/ytSrGsrrbwrB+A=";
      lockfile = ./npm/lockfiles/chrome-devtools-axi.package-lock.json;
      description = "Agent interface for Chrome DevTools";
    };

    chrome-devtools-mcp = mkNpmTool {
      pname = "chrome-devtools-mcp";
      version = "1.11.0";
      tarballHash = "sha256-6fCrl62VFZJ8fZ8KPfvbnqSF0oENVy5KZOuEsZLIvww=";
      npmDepsHash = "sha256-vnn5Eyl4bF2FjGmQpXL1Y0YmAykIqCXeIH4a87uR+sI=";
      lockfile = ./npm/lockfiles/chrome-devtools-mcp.package-lock.json;
      description = "Official Chrome DevTools MCP server and CLI";
      homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
      license = lib.licenses.asl20;
    };

    lavish-axi = mkNpmTool {
      pname = "lavish-axi";
      version = "0.1.90";
      tarballHash = "sha256-m+2dcLX6W90VFKJJN9Lg+b4ExDw5YTIcxrfmup5/kr4=";
      npmDepsHash = "sha256-5ZICIZjRlQvbUiEjnbZF2dc3uZ5J0Zy6/cWPL9TTlSA=";
      lockfile = ./npm/lockfiles/lavish-axi.package-lock.json;
      description = "Agent interface for the Lavish editor";
    };

    tasks-axi = mkNpmTool {
      pname = "tasks-axi";
      version = "0.2.6";
      tarballHash = "sha256-kzQv5sga9RZpvYonP56ImjY0KISHc8yQe64fcak5Cdk=";
      npmDepsHash = "sha256-v69gemOqzKk0REypH4wK66qHVakJSHgj9iv7LOcelFY=";
      lockfile = ./npm/lockfiles/tasks-axi.package-lock.json;
      description = "Agent interface for task management";
    };

    quota-axi = mkNpmTool {
      pname = "quota-axi";
      version = "0.1.64";
      tarballHash = "sha256-RjuA9o4sWbylwal2Rp0t3UQPJmP6Tt/MNF5CUs2e/pc=";
      npmDepsHash = "sha256-xmGR9RFw7KTpnMJ9Gg+J/4eu1qCOeeJvw/uV4NJIC9I=";
      lockfile = ./npm/lockfiles/quota-axi.package-lock.json;
      description = "Agent interface for quota tracking";
    };
  };
}
