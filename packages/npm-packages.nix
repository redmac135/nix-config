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
      version = "0.1.40";
      tarballHash = "sha256-2U0+mGXC72pY9fBEN1jwimut8cRLPPC+1LaSplRy40Y=";
      npmDepsHash = "sha256-wk4Ur6ISnULTvllA7DHRr0kdQwK7LhZPTF1T1DyJs4A=";
      lockfile = ./npm/lockfiles/gh-axi.package-lock.json;
      description = "Agent ergonomic wrapper around GitHub CLI";
    };

    chrome-devtools-axi = mkNpmTool {
      pname = "chrome-devtools-axi";
      version = "0.1.42";
      tarballHash = "sha256-/G2T656WlgtKfOZ3xQ0hIgZEhXdpaa2RzAwVAjJ4+k4=";
      npmDepsHash = "sha256-mdvc7ygb+Px1YIAEsZz6eJBnOGOQxd/55PfZZ+DGmW8=";
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
      version = "0.1.88";
      tarballHash = "sha256-lICNWEbjnvVW++FYnlaej0oOUJtlHiuUVxWCG7hXVN8=";
      npmDepsHash = "sha256-fK7syHHxxT7WfSGc03TyhNLNn8a4ZuzbOs94sUt+xtc=";
      lockfile = ./npm/lockfiles/lavish-axi.package-lock.json;
      description = "Agent interface for the Lavish editor";
    };

    tasks-axi = mkNpmTool {
      pname = "tasks-axi";
      version = "0.2.6";
      tarballHash = "sha256-kzQv5sga9RZpvYonP56ImjY0KISHc8yQe64fcak5Cdk=";
      npmDepsHash = "sha256-C2P1lqelZX12XIqgtXqkarneW177mJfRa+PBiwhIvHY=";
      lockfile = ./npm/lockfiles/tasks-axi.package-lock.json;
      description = "Agent interface for task management";
    };

    quota-axi = mkNpmTool {
      pname = "quota-axi";
      version = "0.1.62";
      tarballHash = "sha256-zaMociFcmenuhkfqj1wp1xSodV9J5StQAKE6WHG0Vhs=";
      npmDepsHash = "sha256-wflBeieF1H/AslA9O+/hSQBW8eOyI51P5ZQ4iElHNng=";
      lockfile = ./npm/lockfiles/quota-axi.package-lock.json;
      description = "Agent interface for quota tracking";
    };
  };
}
