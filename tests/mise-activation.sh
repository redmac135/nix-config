#!/usr/bin/env bash
set -Eeuo pipefail

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

packages=$(nix eval --json --impure --expr '
  let h = (builtins.getFlake (toString ./.)).nixosConfigurations.onhandwsl.config.home-manager.users.ezhao;
  in map (p: p.pname or p.name) h.home.packages
')
python3 -c 'import json,sys
packages=json.loads(sys.argv[1])
names = {p for p in packages}
assert "python3" in names and "gnupg" in names, "mise runtime packages are missing"
' "$packages"

python_pkg=$(nix eval --raw --impure --expr '
  let h = (builtins.getFlake (toString ./.)).nixosConfigurations.onhandwsl.config.home-manager.users.ezhao;
      matches = builtins.filter (p: (p.pname or "") == "python3") h.home.packages;
  in (builtins.elemAt matches 0).outPath
')
python_out=$(nix build --no-link --print-out-paths "$python_pkg")
test -x "$python_out/bin/python"

generation=$(nix build --no-link --print-out-paths --impure \
  '.#nixosConfigurations.onhandwsl.config.home-manager.users.ezhao.home.activationPackage')
grep -q 'export PATH="/etc/profiles/per-user/ezhao/bin:\$PATH"' "$generation/activate"
grep -q 'export CPATH="/etc/profiles/per-user/ezhao/include' "$generation/activate"
grep -q 'export NIX_LD=' "$generation/activate"
grep -q 'export NIX_LD_LIBRARY_PATH=' "$generation/activate"
grep -q 'export MISE_GLOBAL_CONFIG_FILE="\$HOME/.config/mise/config.toml"' "$generation/activate"
grep -q 'timeout --foreground --kill-after=30s 15m' "$generation/activate"
grep -q '/bin/mise install --yes' "$generation/activate"
profile=$(readlink -f "$generation/home-path")
test -f "$profile/include/zlib.h"
test -f "$profile/include/openssl/opensslv.h"
test -x "$profile/bin/gpg"
test -x "$profile/bin/gcc"
test -x "$profile/bin/make"
test -x "$profile/bin/pkg-config"

mise=$(nix build --no-link --print-out-paths nixpkgs#mise)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/mise-activation.XXXXXX")
mkdir -p "$tmp/home"
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/config.toml" <<'EOF'
[tools]
node = "24"
python = "3.12"
EOF
export HOME="$tmp/home"
export MISE_GLOBAL_CONFIG_FILE="$tmp/config.toml"
export MISE_DATA_DIR="$tmp/data"
export MISE_CACHE_DIR="$tmp/cache"
export MISE_NODE_COMPILE=false
export MISE_PYTHON_COMPILE=false
export MISE_NODE_GPG_VERIFY=true
export PATH="$profile/bin:$mise/bin:$PATH"
cd "$tmp"
nixos_stub=0
for loader in /lib/ld-linux*; do
  [[ $(readlink -f "$loader") == *stub-ld* ]] && nixos_stub=1
 done
if ((nixos_stub)) && [[ ! -e /run/current-system/sw/share/nix-ld/lib/ld.so ]]; then
  echo 'mise runtime install skipped: nix-ld is not active in this host generation'
else
  timeout --foreground --kill-after=10s 15m "$mise/bin/mise" install --yes
  node_version=$("$mise/bin/mise" exec -- node --version)
  python_version=$("$mise/bin/mise" exec -- python --version)
  [[ $node_version == v24.* ]]
  [[ $python_version == "Python 3.12."* ]]
  "$mise/bin/mise" exec -- npm --version >/dev/null
fi

echo 'mise activation regression test passed'
