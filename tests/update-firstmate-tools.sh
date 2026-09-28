#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/update-firstmate-tools-test.XXXXXX")
requested_preview=$(mktemp "${TMPDIR:-/tmp}/update-firstmate-tools-requested.XXXXXX")
trap 'rm -rf "$fixture" "$requested_preview"' EXIT
mkdir -p "$fixture/scripts" "$fixture/packages/firstmate/lockfiles" "$fixture/bin"
cp "$ROOT/scripts/update-firstmate-tools" "$fixture/scripts/"
cat > "$fixture/packages/external-tools.nix" <<'EOF'
{ pkgs, lib }:
let
  mkNpmTool = { pname, version, tarballHash, npmDepsHash, lockfile, description }: pkgs.buildNpmPackage {};
in {
  firstmate = {
    alpha-axi = mkNpmTool {
      pname = "alpha-axi";
      version = "0.1.0";
      tarballHash = "sha256-old-alpha";
      npmDepsHash = "sha256-old-deps-alpha";
      lockfile = ./alpha;
      description = "alpha";
    };
    beta-axi = mkNpmTool {
      pname = "beta-axi";
      version = "0.2.0";
      tarballHash = "sha256-old-beta";
      npmDepsHash = "sha256-old-deps-beta";
      lockfile = ./beta;
      description = "beta";
    };
  };
}
EOF
printf '{"version":"old-alpha"}\n' > "$fixture/packages/firstmate/lockfiles/alpha-axi.package-lock.json"
printf '{"version":"old-beta"}\n' > "$fixture/packages/firstmate/lockfiles/beta-axi.package-lock.json"
cat > "$fixture/bin/npm" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
case $1 in
  view) echo '"9.9.9"' ;;
  pack)
    destination=
    while (($#)); do
      if [[ $1 == --pack-destination ]]; then destination=$2; shift 2; else shift; fi
    done
    mkdir -p "$destination/package"
    printf '{"name":"fixture"}\n' > "$destination/package/package.json"
    tar -czf "$destination/fixture.tgz" -C "$destination" package
    ;;
  install) printf '{"lockfileVersion":3,"packages":{}}\n' > package-lock.json ;;
  *) echo "unexpected npm command: $*" >&2; exit 1 ;;
esac
EOF
cat > "$fixture/bin/tarball-hash" <<'EOF'
#!/usr/bin/env bash
echo sha256-new-tarball
EOF
cat > "$fixture/bin/deps-hash" <<'EOF'
#!/usr/bin/env bash
echo sha256-new-deps
EOF
chmod +x "$fixture/bin"/* "$fixture/scripts/update-firstmate-tools"

git -C "$fixture" init -q
git -C "$fixture" config user.email test@example.invalid
git -C "$fixture" config user.name test
git -C "$fixture" add .
git -C "$fixture" commit -qm initial

run() {
  env PATH="$fixture/bin:$PATH" \
    FIRSTMATE_UPDATE_REPO_ROOT="$fixture" \
    FIRSTMATE_UPDATE_TOOLS_FILE="$fixture/packages/external-tools.nix" \
    FIRSTMATE_UPDATE_LOCK_DIR="$fixture/packages/firstmate/lockfiles" \
    FIRSTMATE_UPDATE_TARBALL_HASH_CMD="$fixture/bin/tarball-hash" \
    FIRSTMATE_UPDATE_NPM_DEPS_HASH_CMD="$fixture/bin/deps-hash" \
    "$fixture/scripts/update-firstmate-tools" "$@"
}

if run alpha-axi >/dev/null 2>&1; then
  echo "argument validation accepted missing explicit mode" >&2; exit 1
fi
if run --preview missing-axi >/dev/null 2>&1; then
  echo "package selection accepted undeclared package" >&2; exit 1
fi
printf 'unrelated change\n' > "$fixture/unrelated"
if run --preview alpha-axi >/dev/null 2>&1; then
  echo "dirty working tree was accepted" >&2; exit 1
fi
rm "$fixture/unrelated"
run --preview alpha-axi >/dev/null
git -C "$fixture" diff --exit-code
run --preview alpha-axi 1.2.3 > "$requested_preview"
grep -q 'alpha-axi: 1.2.3' "$requested_preview"
run --apply alpha-axi >/dev/null
grep -q 'version = "9.9.9"' "$fixture/packages/external-tools.nix"
grep -q 'version = "0.2.0"' "$fixture/packages/external-tools.nix"
if grep -q old-alpha "$fixture/packages/firstmate/lockfiles/alpha-axi.package-lock.json"; then
  echo "single-package apply did not replace its lockfile" >&2; exit 1
fi
git -C "$fixture" add . && git -C "$fixture" commit -qm alpha
run --preview --all >/dev/null
git -C "$fixture" diff --exit-code
run --apply --all >/dev/null
grep -q 'version = "9.9.9"' "$fixture/packages/external-tools.nix"

# Force an error after files have been copied. The EXIT trap must restore both
# the Nix expression and lockfile byte-for-byte.
git -C "$fixture" add . && git -C "$fixture" commit -qm all
before_tools=$(sha256sum "$fixture/packages/external-tools.nix")
before_lock=$(sha256sum "$fixture/packages/firstmate/lockfiles/alpha-axi.package-lock.json")
if FIRSTMATE_UPDATE_TEST_FAIL_AFTER=1 run --apply alpha-axi >/dev/null 2>&1; then
  echo "rollback failure hook unexpectedly succeeded" >&2; exit 1
fi
[[ $before_tools == "$(sha256sum "$fixture/packages/external-tools.nix")" ]]
[[ $before_lock == "$(sha256sum "$fixture/packages/firstmate/lockfiles/alpha-axi.package-lock.json")" ]]
git -C "$fixture" diff --exit-code

echo 'update-firstmate-tools tests passed'
