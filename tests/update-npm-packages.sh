#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/update-npm-packages-test.XXXXXX")
requested_preview=$(mktemp "${TMPDIR:-/tmp}/update-npm-packages-requested.XXXXXX")
trap 'rm -rf "$fixture" "$requested_preview"' EXIT
mkdir -p "$fixture/scripts" "$fixture/packages/npm/lockfiles" "$fixture/bin"
cp "$ROOT/scripts/update-npm-packages" "$fixture/scripts/"
cat > "$fixture/packages/npm-packages.nix" <<'EOF'
{ pkgs, lib }:
let
  mkNpmTool = { pname, version, tarballHash, npmDepsHash, lockfile, description }: pkgs.buildNpmPackage {};
in {
  npmPkgs = {
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
    chrome-devtools-mcp = mkNpmTool {
      pname = "chrome-devtools-mcp";
      version = "0.3.0";
      tarballHash = "sha256-old-chrome";
      npmDepsHash = "sha256-old-deps-chrome";
      lockfile = ./chrome;
      description = "Chrome DevTools MCP";
    };
  };
}
EOF
printf '{"version":"old-alpha"}\n' > "$fixture/packages/npm/lockfiles/alpha-axi.package-lock.json"
printf '{"version":"old-beta"}\n' > "$fixture/packages/npm/lockfiles/beta-axi.package-lock.json"
printf '{"version":"old-chrome"}\n' > "$fixture/packages/npm/lockfiles/chrome-devtools-mcp.package-lock.json"
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
chmod +x "$fixture/bin"/* "$fixture/scripts/update-npm-packages"

git -C "$fixture" init -q
git -C "$fixture" config user.email test@example.invalid
git -C "$fixture" config user.name test
git -C "$fixture" add .
git -C "$fixture" commit -qm initial

run() {
  env PATH="$fixture/bin:$PATH" \
    NPM_PACKAGES_UPDATE_REPO_ROOT="$fixture" \
    NPM_PACKAGES_UPDATE_TOOLS_FILE="$fixture/packages/npm-packages.nix" \
    NPM_PACKAGES_UPDATE_LOCK_DIR="$fixture/packages/npm/lockfiles" \
    NPM_PACKAGES_UPDATE_TARBALL_HASH_CMD="$fixture/bin/tarball-hash" \
    NPM_PACKAGES_UPDATE_NPM_DEPS_HASH_CMD="$fixture/bin/deps-hash" \
    "$fixture/scripts/update-npm-packages" "$@"
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
run --preview chrome-devtools-mcp 1.2.3 > "$requested_preview"
grep -q 'chrome-devtools-mcp: 1.2.3' "$requested_preview"
run --apply chrome-devtools-mcp >/dev/null
grep -q 'version = "9.9.9"' "$fixture/packages/npm-packages.nix"
if grep -q old-chrome "$fixture/packages/npm/lockfiles/chrome-devtools-mcp.package-lock.json"; then
  echo "chrome-devtools-mcp apply did not replace its lockfile" >&2; exit 1
fi
git -C "$fixture" add . && git -C "$fixture" commit -qm chrome-devtools-mcp
run --apply alpha-axi >/dev/null
grep -q 'version = "9.9.9"' "$fixture/packages/npm-packages.nix"
grep -q 'version = "0.2.0"' "$fixture/packages/npm-packages.nix"
if grep -q old-alpha "$fixture/packages/npm/lockfiles/alpha-axi.package-lock.json"; then
  echo "single-package apply did not replace its lockfile" >&2; exit 1
fi
git -C "$fixture" add . && git -C "$fixture" commit -qm alpha
run --preview --all >/dev/null
git -C "$fixture" diff --exit-code
run --apply --all >/dev/null
grep -q 'version = "9.9.9"' "$fixture/packages/npm-packages.nix"

# Verify rollback after a write failure.
git -C "$fixture" add . && git -C "$fixture" commit -qm all
before_tools=$(sha256sum "$fixture/packages/npm-packages.nix")
before_lock=$(sha256sum "$fixture/packages/npm/lockfiles/alpha-axi.package-lock.json")
if NPM_PACKAGES_UPDATE_TEST_FAIL_AFTER=1 run --apply alpha-axi >/dev/null 2>&1; then
  echo "rollback failure hook unexpectedly succeeded" >&2; exit 1
fi
[[ $before_tools == "$(sha256sum "$fixture/packages/npm-packages.nix")" ]]
[[ $before_lock == "$(sha256sum "$fixture/packages/npm/lockfiles/alpha-axi.package-lock.json")" ]]
git -C "$fixture" diff --exit-code

echo 'update-npm-packages tests passed'
