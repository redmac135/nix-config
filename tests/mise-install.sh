#!/usr/bin/env bash
set -Eeuo pipefail

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
configuration=${1:-onhandwsl}
case $configuration in
  onhandwsl|pancakewsl) ;;
  *) echo "usage: $0 [onhandwsl|pancakewsl]" >&2; exit 2 ;;
esac

packages=$(nix eval --json --impure --expr "
  let h = (builtins.getFlake (toString ./.)).nixosConfigurations.${configuration}.config.home-manager.users.ezhao;
  in map (p: p.pname or p.name) h.home.packages
")
python3 -c 'import json,sys
packages=json.loads(sys.argv[1])
names = {p for p in packages}
assert "python3" in names and "gnupg" in names, "mise runtime packages are missing"
' "$packages"

python_pkg=$(nix eval --raw --impure --expr "
  let h = (builtins.getFlake (toString ./.)).nixosConfigurations.${configuration}.config.home-manager.users.ezhao;
      matches = builtins.filter (p: (p.pname or \"\") == \"python3\") h.home.packages;
  in (builtins.elemAt matches 0).outPath
")
python_out=$(nix build --no-link --print-out-paths "$python_pkg")
test -x "$python_out/bin/python"

profile=$(nix build --no-link --print-out-paths --impure \
  ".#nixosConfigurations.${configuration}.config.home-manager.users.ezhao.home.path")
test -f "$profile/include/zlib.h"
test -f "$profile/include/openssl/opensslv.h"
test -x "$profile/bin/gpg"
test -x "$profile/bin/gcc"
test -x "$profile/bin/make"
test -x "$profile/bin/pkg-config"

mise=$(nix build --no-link --print-out-paths nixpkgs#mise)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/mise-install.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
cp files/mise/config.toml "$tmp/config.toml"
real_home=$(getent passwd "$(id -u)" | cut -d: -f6)
export HOME="$real_home"
export MISE_GLOBAL_CONFIG_FILE="$tmp/config.toml"
export MISE_DATA_DIR="$tmp/data"
export MISE_CACHE_DIR="$tmp/cache"
export RUSTUP_HOME="$tmp/rustup"
export CARGO_HOME="$tmp/cargo"
export MISE_NODE_GPG_VERIFY=false
export PATH="$profile/bin:$mise/bin:$PATH"
cd "$tmp"
nixos_stub=0
for loader in /lib/ld-linux*; do
  [[ $(readlink -f "$loader") == *stub-ld* ]] && nixos_stub=1
 done
if ((nixos_stub)) && [[ ! -e /run/current-system/sw/share/nix-ld/lib/ld.so ]]; then
  echo 'mise runtime install skipped: nix-ld is not active in this host generation'
else
  timeout --foreground --kill-after=10s 4m "$mise/bin/mise" install --yes
  node_version=$("$mise/bin/mise" exec -- node --version)
  python_version=$("$mise/bin/mise" exec -- python --version)
  [[ $node_version == v24.* ]]
  [[ $python_version == "Python 3.12."* ]]
  "$mise/bin/mise" exec -- npm --version >/dev/null
fi

echo 'mise manual-install regression test passed'
