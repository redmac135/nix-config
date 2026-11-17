#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
configuration=${1:-onhandwsl}
case $configuration in
  onhandwsl | pancakewsl) ;;
  *) echo "usage: $0 [onhandwsl|pancakewsl]" >&2; exit 2 ;;
esac

# Exercise the evaluated Pi activation fragment, without running Herdr or
# installing anything in the user's home. The runner checks the exact PATH Pi
# and its npm lifecycle scripts receive.
activation=$(nix eval --raw "$ROOT#nixosConfigurations.${configuration}.config.home-manager.users.ezhao.home.activation.installAgentExtensions.data")
[[ $activation == *'pi_agent_dir='* ]]
fragment="pi_agent_dir=${activation#*pi_agent_dir=}"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp" PI_CODING_AGENT_DIR="$tmp/agent"
mkdir -p "$PI_CODING_AGENT_DIR"

run() {
  [[ $# == 3 && $1 == /nix/store/*/bin/pi && $2 == install && $3 == npm:@ygncode/pi-web@beta ]]
  [[ $(command -v pi) == "$1" ]]
  [[ $(command -v npm) == /nix/store/*/bin/npm ]]
  [[ $(command -v node) == /nix/store/*/bin/node ]]
  [[ $(command -v curl) == /nix/store/*/bin/curl ]]
  npm --version >/dev/null
  curl --version >/dev/null
  printf 'called\n' >> "$HOME/calls"
}

# Keep only standard activation tools, not the interactive user's mise PATH.
coreutils=$(nix eval --raw "$ROOT#nixosConfigurations.${configuration}.pkgs.coreutils.outPath")
bash_package=$(nix eval --raw "$ROOT#nixosConfigurations.${configuration}.pkgs.bash.outPath")
PATH="$coreutils/bin:$bash_package/bin"
original_path=$PATH
eval "$fragment"
[[ $PATH == "$original_path" ]]
[[ $(wc -l < "$HOME/calls") == 1 ]]

for settings in \
  '{"packages":["npm:@ygncode/pi-web@beta"]}' \
  '{"packages":[{"source":"npm:@ygncode/pi-web"}]}' ; do
  printf '%s\n' "$settings" > "$PI_CODING_AGENT_DIR/settings.json"
  eval "$fragment"
  [[ $(wc -l < "$HOME/calls") == 1 ]]
done
printf '%s\n' '{"packages":["npm:@ygncode/pi-web-extra"]}' > "$PI_CODING_AGENT_DIR/settings.json"
eval "$fragment"
[[ $(wc -l < "$HOME/calls") == 2 ]]
[[ $(<"$PI_CODING_AGENT_DIR/settings.json") == '{"packages":["npm:@ygncode/pi-web-extra"]}' ]]

# An installer failure must fail activation instead of silently succeeding.
status=0
(
  run() { return 42; }
  eval "$fragment"
) || status=$?
[[ $status == 42 ]]
[[ $PATH == "$original_path" ]]
echo 'agent extension activation tests passed'
