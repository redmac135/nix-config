#!/usr/bin/env bash
set -Eeuo pipefail

mise=${1:-mise}
: "${CARGO_HOME:?CARGO_HOME must point to the mise Rust installation}"
export MISE_AUTO_INSTALL=0 MISE_EXEC_AUTO_INSTALL=0

# Do not let an unrelated working compiler on PATH mask a broken rustup install.
[[ $("$mise" which cargo) == "$CARGO_HOME/bin/cargo" ]]
[[ $("$mise" which rustc) == "$CARGO_HOME/bin/rustc" ]]
"$mise" exec -- bash -c '
  [[ $(command -v cargo) == "$CARGO_HOME/bin/cargo" ]]
  [[ $(command -v rustc) == "$CARGO_HOME/bin/rustc" ]]
'
"$mise" exec -- cargo --version
"$mise" exec -- rustc --version

tmp=$(mktemp -d "${TMPDIR:-/tmp}/mise-rust-smoke.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/src"
printf '[package]\nname = "mise-rust-smoke"\nversion = "0.1.0"\nedition = "2021"\n' > "$tmp/Cargo.toml"
printf 'fn main() { println!("mise rust works"); }\n' > "$tmp/src/main.rs"
output=$("$mise" exec -- cargo run --offline --quiet --manifest-path "$tmp/Cargo.toml")
[[ $output == 'mise rust works' ]]
