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
      version = "0.1.38";
      tarballHash = "sha256-8rdIHX9uoq5Cg1LE+kVv89BDah3mNG5BgT8gqJ7lqBg=";
      npmDepsHash = "sha256-lK2Wm2lD1mDVDSTxV3RThK3ycr6WuTnFyf8HKH3tyOg=";
      lockfile = ./npm/lockfiles/gh-axi.package-lock.json;
      description = "Agent ergonomic wrapper around GitHub CLI";
    };

    chrome-devtools-axi = mkNpmTool {
      pname = "chrome-devtools-axi";
      version = "0.1.40";
      tarballHash = "sha256-iEym43T1pF4FFAcggAPeMOibACZTxQu7gVJlRqn1hkk=";
      npmDepsHash = "sha256-kEFO+mv4Y2JvK0mEcz1p0c7uRnZjmR3uZvRb/Tie8a8=";
      lockfile = ./npm/lockfiles/chrome-devtools-axi.package-lock.json;
      description = "Agent interface for Chrome DevTools";
    };

    chrome-devtools-mcp = mkNpmTool {
      pname = "chrome-devtools-mcp";
      version = "1.10.1";
      tarballHash = "sha256-ASy89ugy1PZwna0MIde+8XCJ6Ure6c8zF50V6gqa3ys=";
      npmDepsHash = "sha256-dqGVwQNrEtonag6dHUSftAUGsQYexqLN1i0wBo22QAk=";
      lockfile = ./npm/lockfiles/chrome-devtools-mcp.package-lock.json;
      description = "Official Chrome DevTools MCP server and CLI";
      homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
      license = lib.licenses.asl20;
    };

    lavish-axi = mkNpmTool {
      pname = "lavish-axi";
      version = "0.1.87";
      tarballHash = "sha256-FKyG/JQgEenrlbHWP/FAAY4Tsb9q3/Cc9QTClxtL7TE=";
      npmDepsHash = "sha256-RtJP6myY3x94vSFFXqnb6h2Anxcl0tWpYuefAw+3zV8=";
      lockfile = ./npm/lockfiles/lavish-axi.package-lock.json;
      description = "Agent interface for the Lavish editor";
    };

    tasks-axi = mkNpmTool {
      pname = "tasks-axi";
      version = "0.2.6";
      tarballHash = "sha256-kzQv5sga9RZpvYonP56ImjY0KISHc8yQe64fcak5Cdk=";
      npmDepsHash = "sha256-GzFu8Yc6eSU4k0Jl7j9HHtj/chC2scgQqZor1ZuLv9U=";
      lockfile = ./npm/lockfiles/tasks-axi.package-lock.json;
      description = "Agent interface for task management";
    };

    quota-axi = mkNpmTool {
      pname = "quota-axi";
      version = "0.1.61";
      tarballHash = "sha256-DfrtKxk34zZFWG9b7/bGnhiuaHusbW63Efnjt44pRsc=";
      npmDepsHash = "sha256-qkJc7nNuYa6ZzWyShk73JBcIBqoaSNOs2jqjHobsnBo=";
      lockfile = ./npm/lockfiles/quota-axi.package-lock.json;
      description = "Agent interface for quota tracking";
    };
  };
}
