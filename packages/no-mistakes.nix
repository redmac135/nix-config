{
  pkgs,
  lib,
}: {
  noMistakes = let
    version = "1.84.0";
  in
    pkgs.buildGoModule {
      pname = "no-mistakes";
      inherit version;
      src = pkgs.fetchFromGitHub {
        owner = "kunchenguid";
        repo = "no-mistakes";
        rev = "v${version}";
        hash = "sha256-ne+JfVfV0jjMldqyv25KTwrdexFs5ynFAGWgILiGPAk=";
      };
      vendorHash = "sha256-maAVBptEtdrGanJHwAPAmuGBorzIMUgK6T+NmIz1kS0=";
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
