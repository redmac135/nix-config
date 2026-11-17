{flake}: let
  names = ["gh-axi" "chrome-devtools-axi" "chrome-devtools-mcp" "lavish-axi" "tasks-axi" "quota-axi"];
  check = host: let
    cfg = flake.nixosConfigurations.${host}.config;
    pkgs = flake.nixosConfigurations.${host}.pkgs;
    packages = cfg.home-manager.users.ezhao.home.packages;
    count = p: builtins.length (builtins.filter (x: toString x == toString p) packages);
  in
    builtins.all (name: count pkgs.firstmateTools.${name} == 1) names
    && count pkgs.chromium == 1
    && cfg.home-manager.users.ezhao.home.sessionVariables.CHROME_DEVTOOLS_AXI_EXECUTABLE_PATH == "${pkgs.chromium}/bin/chromium";
in
  assert check "onhandwsl";
  assert check "pancakewsl";
    true
