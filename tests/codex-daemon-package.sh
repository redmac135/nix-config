#!/usr/bin/env bash
set -Eeuo pipefail

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
configuration=${1:-onhandwsl}
case $configuration in
  onhandwsl|pancakewsl) ;;
  *) echo "usage: $0 [onhandwsl|pancakewsl]" >&2; exit 2 ;;
esac

package=$(nix build --no-link --print-out-paths ".#nixosConfigurations.${configuration}.pkgs.llmAgents.codex")
codex="$package/bin/codex"
tmp=$(mktemp -d "$root/.codex-daemon-package.XXXXXX")
export HOME="$tmp/home"
export CODEX_HOME="$HOME/.codex"
mkdir -p "$HOME" "$CODEX_HOME"
cleanup() {
  timeout --foreground --kill-after=5s 30s "$codex" app-server daemon stop >/dev/null 2>&1 || true
  rm -rf "$tmp"
}
trap cleanup EXIT

timeout --foreground --kill-after=5s 60s "$codex" app-server daemon start
installed="$CODEX_HOME/packages/app-server-daemon/current"
test -f "$installed/codex-package.json"
for file in bin/codex bin/codex-code-mode-host codex-path/rg codex-resources/bwrap; do
  test -x "$installed/$file"
done

echo 'Codex daemon package regression test passed'
