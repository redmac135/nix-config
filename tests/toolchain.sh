#!/usr/bin/env bash
set -Eeuo pipefail

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
configuration=${1:-onhandwsl}
case $configuration in
  onhandwsl) system=aarch64-linux ;;
  pancakewsl) system=x86_64-linux ;;
  *) echo "usage: $0 [onhandwsl|pancakewsl]" >&2; exit 2 ;;
esac
[[ $(nix eval --raw --impure --expr builtins.currentSystem) == "$system" ]] || {
  echo "toolchain test must run on $system" >&2; exit 2;
}

# Verify that the home profile and shell use the same locked packages.
export TOOLCHAIN_ROOT="$root"
paths=$(nix eval --json --impure --expr "
  let f = builtins.getFlake (builtins.getEnv \"TOOLCHAIN_ROOT\");
      p = f.inputs.nixpkgs.legacyPackages.${system};
      home = f.nixosConfigurations.${configuration}.config.home-manager.users.ezhao;
      paths = map (pkg: pkg.outPath) home.home.packages;
  in assert builtins.all (pkg: builtins.elem pkg.outPath paths) [ p.nodejs_24 p.rustc p.cargo ];
     map (pkg: pkg.outPath) [ p.nodejs_24 p.rustc p.cargo p.rust-analyzer ]
")
readarray -t expected < <(python3 -c 'import json,sys; print(*json.loads(sys.argv[1]), sep="\n")' "$paths")
tmp=$(mktemp -d "${TMPDIR:-/tmp}/nix-toolchain.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/home" "$tmp/shims" "$tmp/project/src"
for tool in node npm rustc cargo rust-analyzer; do
  printf '#!/bin/sh\necho unexpected shim >&2\nexit 99\n' > "$tmp/shims/$tool"
  chmod +x "$tmp/shims/$tool"
done
printf '[package]\nname = "toolchain-smoke"\nversion = "0.1.0"\nedition = "2021"\n' > "$tmp/project/Cargo.toml"
printf 'fn main() { println!("toolchain-ok"); }\n' > "$tmp/project/src/main.rs"
export HOME="$tmp/home" CARGO_HOME="$tmp/cargo" RUSTUP_HOME="$tmp/rustup"
export RUSTUP_TOOLCHAIN=nonexistent PATH="$tmp/shims:$PATH"
export EXPECT_NODE="${expected[0]}" EXPECT_RUSTC="${expected[1]}" EXPECT_CARGO="${expected[2]}" EXPECT_LSP="${expected[3]}"
export TEST_PROJECT="$tmp/project" TEST_LOCK="$root/packages/npm/lockfiles/gh-axi.package-lock.json"
nix develop --no-write-lock-file "$root#toolchain" -c bash -euc '
  [[ $(command -v node) == "$EXPECT_NODE/bin/node" ]]
  [[ $(command -v npm) == "$EXPECT_NODE/bin/npm" ]]
  [[ $(command -v rustc) == "$EXPECT_RUSTC/bin/rustc" ]]
  [[ $(command -v cargo) == "$EXPECT_CARGO/bin/cargo" ]]
  [[ $(command -v rust-analyzer) == "$EXPECT_LSP/bin/rust-analyzer" ]]
  node --version; npm --version; rustc --version; cargo --version; rust-analyzer --version
  # Exercise a real vendored npm lockfile used by this repository, offline.
  node -e '\''const l = require(process.env.TEST_LOCK); if (l.name !== "gh-axi" || !l.lockfileVersion || !l.packages[""]) process.exit(1)'\''
  cargo build --offline --manifest-path "$TEST_PROJECT/Cargo.toml"
  [[ $("$TEST_PROJECT/target/debug/toolchain-smoke") == toolchain-ok ]]
'
echo 'Nix toolchain regression test passed'
