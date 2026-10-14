{
  pkgs,
  lib,
}: {
  noMistakes = let
    version = "1.75.2";
  in
    pkgs.buildGoModule {
      pname = "no-mistakes";
      inherit version;
      src = pkgs.fetchFromGitHub {
        owner = "kunchenguid";
        repo = "no-mistakes";
        rev = "v${version}";
        hash = "sha256-57JRCgx08AtYDPBrMpIXWTtNyhrP/+/BIYNKcSjIthU=";
      };
      vendorHash = "sha256-NZOYxNYvt4192uqKBdKRxdgrKFvWx3585psdCnRdPSM=";
      subPackages = ["cmd/no-mistakes"];
      ldflags = [
        "-X github.com/kunchenguid/no-mistakes/internal/buildinfo.Version=v${version}"
        "-X github.com/kunchenguid/no-mistakes/internal/buildinfo.TelemetryHost=https://a.kunchenguid.com"
        "-X github.com/kunchenguid/no-mistakes/internal/buildinfo.TelemetryWebsiteID=f959e889-92f5-4121-8a1f-571b10861198"
      ];
      meta = {
        description = "Local Git proxy that validates code before pushing";
        homepage = "https://github.com/kunchenguid/no-mistakes";
        license = lib.licenses.mit;
      };
    };
}
