#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
configuration=${1:-onhandwsl}
case $configuration in
  onhandwsl | pancakewsl) ;;
  *) echo "usage: $0 [onhandwsl|pancakewsl]" >&2; exit 2 ;;
esac

nvim=$(nix build --no-link --print-out-paths "$ROOT#nixosConfigurations.${configuration}.config.home-manager.users.ezhao.programs.neovim.finalPackage")/bin/nvim
pack_attr="$ROOT#nixosConfigurations.${configuration}.config.home-manager.users.ezhao.xdg.dataFile.\"nvim/site/pack/hm\".source"
pack=$(nix eval --raw "$pack_attr")
pack_drv=$(nix eval --raw "$pack_attr" --apply 'x: builtins.head (builtins.attrNames (builtins.getContext x))')
nix-store --realise "$pack_drv" >/dev/null
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/config" XDG_STATE_HOME="$tmp/state" XDG_DATA_HOME="$tmp/data" XDG_CACHE_HOME="$tmp/cache"
export CARGO_HOME="$tmp/cargo" CARGO_TARGET_DIR="$tmp/target" CARGO_NET_OFFLINE=true
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$tmp/project/src" "$tmp/bin"
ln -s "$ROOT/nvim" "$XDG_CONFIG_HOME/nvim"
mkdir -p "$XDG_DATA_HOME/nvim/site/pack"
ln -s "$pack" "$XDG_DATA_HOME/nvim/site/pack/hm"
printf '[package]\nname = "nvim-open-test"\nversion = "0.1.0"\nedition = "2021"\n' > "$tmp/project/Cargo.toml"
printf 'fn main() { println!("hello"); }\n' > "$tmp/project/src/main.rs"
printf 'local value = 42\n' > "$tmp/project/example.lua"
# A broken PATH shim must not shadow the Nix-managed server.
printf '#!/bin/sh\necho shim-invoked > "$HOME/shim-invoked"\nexit 1\n' > "$tmp/bin/rust-analyzer"
chmod +x "$tmp/bin/rust-analyzer"
export PATH="$tmp/bin:$PATH" NVIM_TEST_PROJECT="$tmp/project"
( cd "$tmp/project" && "$nvim" --headless -i NONE -n src/main.rs -c "luafile $ROOT/tests/nvim-open.lua" )
[[ ! -e "$HOME/shim-invoked" ]]
echo 'Neovim representative file-opening tests passed'
