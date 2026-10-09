#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/update-firstmate-tools-and-flake-test.XXXXXX")
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/scripts" "$fixture/bin"
cp "$ROOT/scripts/update-firstmate-tools-and-flake" "$fixture/scripts/"
cat > "$fixture/scripts/fake-updater" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
[[ $* == '--apply --all' ]]
printf 'firstmate update\n' >> update.log
EOF
cat > "$fixture/bin/nix" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
[[ $* == 'flake update' ]]
printf 'flake update\n' >> update.log
EOF
chmod +x "$fixture/scripts/update-firstmate-tools-and-flake" "$fixture/scripts/fake-updater" "$fixture/bin/nix"

printf 'flake\n' > "$fixture/flake.nix"
git -C "$fixture" init -q
git -C "$fixture" config user.email test@example.invalid
git -C "$fixture" config user.name test
git -C "$fixture" add .
git -C "$fixture" commit -qm initial

env PATH="$fixture/bin:$PATH" \
  FIRSTMATE_UPDATE_REPO_ROOT="$fixture" \
  FIRSTMATE_UPDATE_UPDATER="$fixture/scripts/fake-updater" \
  "$fixture/scripts/update-firstmate-tools-and-flake" >/dev/null

[[ $(sed -n '1p' "$fixture/update.log") == 'firstmate update' ]]
[[ $(sed -n '2p' "$fixture/update.log") == 'flake update' ]]
git -C "$fixture" diff --check

echo 'update-firstmate-tools-and-flake tests passed'
