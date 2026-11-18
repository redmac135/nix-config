#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/update-dependencies-test.XXXXXX")
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/scripts" "$fixture/bin"
cp "$ROOT/scripts/update-dependencies" "$fixture/scripts/"
cat > "$fixture/bin/nix" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
if [[ $* == 'run .#nix-update -- noMistakes --flake --override-filename packages/no-mistakes.nix --use-github-releases' ]]; then
  [[ ${GITHUB_TOKEN:-} == "${TEST_EXPECT_TOKEN:-}" ]] || exit 1
  printf 'no-mistakes update\n' >> update.log
  if [[ ${TEST_FAIL_UPDATE:-} == 1 ]]; then
    echo 'HTTP Error 403: rate limit exceeded' >&2
    exit 1
  fi
elif [[ $* == 'flake update' ]]; then
  printf 'flake update\n' >> update.log
else
  exit 1
fi
EOF
chmod +x "$fixture/bin/nix"
printf 'flake\n' > "$fixture/flake.nix"
git -C "$fixture" init -q
git -C "$fixture" config user.email test@example.invalid
git -C "$fixture" config user.name test
git -C "$fixture" add .
git -C "$fixture" commit -qm initial

env PATH="$fixture/bin:$PATH" NPM_PACKAGES_UPDATE_REPO_ROOT="$fixture" GITHUB_TOKEN=test-token TEST_EXPECT_TOKEN=test-token \
  "$fixture/scripts/update-dependencies" >/dev/null
[[ $(sed -n '1p' "$fixture/update.log") == 'no-mistakes update' ]]
[[ $(sed -n '2p' "$fixture/update.log") == 'flake update' ]]
[[ $(wc -l < "$fixture/update.log") == 2 ]]
git -C "$fixture" diff --check

: > "$fixture/update.log"
env -u GITHUB_TOKEN PATH="$fixture/bin:$PATH" NPM_PACKAGES_UPDATE_REPO_ROOT="$fixture" \
  "$fixture/scripts/update-dependencies" >/dev/null
[[ $(wc -l < "$fixture/update.log") == 2 ]]

: > "$fixture/update.log"
if env PATH="$fixture/bin:$PATH" NPM_PACKAGES_UPDATE_REPO_ROOT="$fixture" GITHUB_TOKEN=test-token TEST_EXPECT_TOKEN=test-token TEST_FAIL_UPDATE=1 \
  "$fixture/scripts/update-dependencies" >"$fixture/output" 2>&1; then
  echo 'expected updater failure' >&2
  exit 1
fi
grep -q 'HTTP Error 403: rate limit exceeded' "$fixture/output"
grep -q 'set GITHUB_TOKEN or wait for the limit to reset' "$fixture/output"
! grep -q 'test-token' "$fixture/output"
[[ $(wc -l < "$fixture/update.log") == 1 ]]
# Keep the API token separate from the scoped private-input credential.
grep -Fq 'GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}' "$ROOT/.github/workflows/update-dependencies.yml"
grep -Fq 'FIRSTMATE_NIX_TOKEN: ${{ secrets.FIRSTMATE_NIX_READ_TOKEN }}' "$ROOT/.github/workflows/update-dependencies.yml"
echo 'update-dependencies tests passed'
