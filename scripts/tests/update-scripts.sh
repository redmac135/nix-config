#!/usr/bin/env bash
set -euo pipefail

scripts_dir=$(cd "$(dirname "$0")/.." && pwd -P)
real_git=$(command -v git)
real_jq=$(command -v jq)
real_tar=$(command -v tar)
tests=0

die() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

pass() {
  tests=$((tests + 1))
  printf 'ok %d - %s\n' "$tests" "$1"
}

expect_failure() {
  local output=$1
  shift
  if "$@" >"$output" 2>&1; then
    die "command unexpectedly succeeded: $*"
  fi
}

checksum() {
  sha256sum "$@" | awk '{print $1}' | paste -sd: -
}

new_fixture() {
  fixture=$(mktemp -d "${TMPDIR:-/tmp}/update-script-test.XXXXXX")
  mockbin=$fixture/mockbin
  mkdir -p "$mockbin" "$fixture/packages/firstmate/lockfiles" "$fixture/packages/pi-web/lockfiles"

  cat >"$fixture/flake.nix" <<'EOF'
{ inputs = {}; outputs = _: {}; }
EOF
  cat >"$fixture/flake.lock" <<'EOF'
{
  "nodes": {
    "root": { "inputs": { "bar": "bar", "foo": "foo" } },
    "foo": { "locked": { "rev": "foo-old", "narHash": "sha256-old" }, "original": { "type": "github" } },
    "bar": { "locked": { "rev": "bar-old", "narHash": "sha256-old" }, "original": { "type": "github" } }
  },
  "root": "root",
  "version": 7
}
EOF
  cat >"$fixture/packages/external-tools.nix" <<'EOF'
{ pkgs, lib }: let
  mkNpmTool = args: args;
in {
  firstmate = {
    no-mistakes = pkgs.buildGoModule {
      pname = "no-mistakes";
      version = "1.0.0";
      src = pkgs.fetchFromGitHub {
        owner = "kunchenguid";
        repo = "no-mistakes";
        rev = "v1.0.0";
        hash = "sha256-oldsource=";
      };
      vendorHash = "sha256-oldvendor=";
      subPackages = ["cmd/no-mistakes"];
      ldflags = [
        "-X github.com/kunchenguid/no-mistakes/internal/buildinfo.Version=v1.0.0"
        "-X github.com/kunchenguid/no-mistakes/internal/buildinfo.Commit=aaaaaaaa"
        "-X github.com/kunchenguid/no-mistakes/internal/buildinfo.Date=2026-01-01"
      ];
    };
    gh-axi = mkNpmTool {
      pname = "gh-axi";
      version = "0.1.0";
      tarballHash = "sha256-oldtar=";
      npmDepsHash = "sha256-olddeps=";
      lockfile = ./firstmate/lockfiles/gh-axi.package-lock.json;
    };
  };
  pi-web = mkNpmTool {
    pname = "pi-web";
    version = "1.0.0";
    tarballHash = "sha256-oldpi=";
    npmDepsHash = "sha256-oldpideps=";
    lockfile = ./pi-web/lockfiles/pi-web.package-lock.json;
  };
}
EOF
  cat >"$fixture/packages/firstmate/lockfiles/gh-axi.package-lock.json" <<'EOF'
{"name":"gh-axi","version":"0.1.0","lockfileVersion":3,"packages":{}}
EOF
  cat >"$fixture/packages/pi-web/lockfiles/pi-web.package-lock.json" <<'EOF'
{"name":"@jmfederico/pi-web","version":"1.0.0","lockfileVersion":3,"packages":{}}
EOF

  cat >"$mockbin/uname" <<'EOF'
#!/usr/bin/env bash
printf 'aarch64\n'
EOF
  cat >"$mockbin/git" <<'EOF'
#!/usr/bin/env bash
if [[ ${1:-} == ls-remote ]]; then
  printf 'f627beb7ffa8aceee353fb1deb88f40ae8611ad6\trefs/tags/v1.53.0\n'
  exit 0
fi
exec "$REAL_GIT" "$@"
EOF
  cat >"$mockbin/gh-axi" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *releases/tags/v1.53.0*)
    cat <<'OUT'
tag_name: v1.53.0
draft: false
prerelease: false
OUT
    ;;
  *commits/f627beb7ffa8aceee353fb1deb88f40ae8611ad6*)
    cat <<'OUT'
sha: f627beb7ffa8aceee353fb1deb88f40ae8611ad6
commit:
  committer:
    date: "2026-08-16T16:52:02Z"
OUT
    ;;
  *) exit 1 ;;
esac
EOF
  cat >"$mockbin/npm" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  view)
    spec=$3
    name=${spec%@*}
    version=${spec##*@}
    [[ -n $name ]] || name=${spec%@*}
    base=${name##*/}
    cat <<OUT
{"name":"$name","version":"$version","dist.tarball":"https://registry.npmjs.org/$name/-/$base-$version.tgz","dist.integrity":"sha512-testintegrity=="}
OUT
    ;;
  pack)
    spec=$2
    name=${spec%@*}
    version=${spec##*@}
    base=${name##*/}
    destination=
    while (($#)); do
      if [[ $1 == --pack-destination ]]; then destination=$2; break; fi
      shift
    done
    work=$(mktemp -d)
    mkdir -p "$work/package"
    printf '{"name":"%s","version":"%s"}\n' "$name" "$version" >"$work/package/package.json"
    "$REAL_TAR" -czf "$destination/$base-$version.tgz" -C "$work" package
    rm -rf "$work"
    printf '[{"filename":"%s-%s.tgz","integrity":"sha512-testintegrity=="}]\n' "$base" "$version"
    ;;
  install)
    name=$("$REAL_JQ" -r .name package.json)
    version=$("$REAL_JQ" -r .version package.json)
    printf '{"name":"%s","version":"%s","lockfileVersion":3,"packages":{}}\n' "$name" "$version" >package-lock.json
    ;;
  *) exit 1 ;;
esac
EOF
  cat >"$mockbin/nix" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ ${1:-} == flake && ${2:-} == update ]]; then
  reference=
  output=
  while (($#)); do
    case "$1" in
      --reference-lock-file) reference=$2; shift 2 ;;
      --output-lock-file) output=$2; shift 2 ;;
      *) shift ;;
    esac
  done
  cp "$reference" "$output"
  case "${MOCK_NIX_MODE:-change}" in
    nochange) ;;
    unrelated)
      "$REAL_JQ" '.nodes.foo.locked.rev="foo-new" | .nodes.bar.locked.rev="bar-new"' "$output" >"$output.new"
      mv "$output.new" "$output"
      ;;
    *)
      "$REAL_JQ" '.nodes.foo.locked.rev="foo-new"' "$output" >"$output.new"
      mv "$output.new" "$output"
      ;;
  esac
  exit 0
fi
if [[ ${1:-} == flake && ${2:-} == prefetch ]]; then
  printf '{"hash":"sha256-newsource="}\n'
  exit 0
fi
if [[ ${1:-} == hash && ${2:-} == file ]]; then
  printf 'sha256-newtar=\n'
  exit 0
fi
if [[ ${1:-} == run ]]; then
  printf 'sha256-newdeps=\n'
  exit 0
fi
if [[ ${1:-} == build ]]; then
  if [[ ${MOCK_NIX_NO_MISTAKES:-} == 1 ]]; then
    count_file=${MOCK_NIX_COUNT:?}
    count=0
    [[ -f $count_file ]] && count=$(<"$count_file")
    count=$((count + 1))
    printf '%s\n' "$count" >"$count_file"
    if [[ $count -eq 1 ]]; then
      printf 'error: hash mismatch in fixed-output derivation\n  specified: sha256-AAAAAAAA\n       got: sha256-newvendor=\n' >&2
      exit 1
    fi
    if [[ ${MOCK_NIX_MODE:-} == build-fail ]]; then
      printf 'package build failed\n' >&2
      exit 1
    fi
    mkdir -p "$MOCK_NIX_OUT/bin"
    cat >"$MOCK_NIX_OUT/bin/no-mistakes" <<'BIN'
#!/usr/bin/env bash
printf 'no-mistakes version v1.53.0 (f627beb7) 2026-08-16\n'
BIN
    chmod +x "$MOCK_NIX_OUT/bin/no-mistakes"
    printf '%s\n' "$MOCK_NIX_OUT"
    exit 0
  fi
  [[ ${MOCK_NIX_MODE:-} != build-fail ]] || exit 1
  exit 0
fi
exit 1
EOF
  chmod +x "$mockbin"/*

  (
    cd "$fixture"
    "$real_git" init -q
    "$real_git" config user.email tests@example.invalid
    "$real_git" config user.name Tests
    "$real_git" add .
    "$real_git" commit -qm fixture
  )
  export PATH="$mockbin:$ORIGINAL_PATH" REAL_GIT="$real_git" REAL_JQ="$real_jq" REAL_TAR="$real_tar"
}

ORIGINAL_PATH=$PATH
trap '[[ -z ${fixture:-} ]] || rm -rf "$fixture"' EXIT

new_fixture
before=$(checksum "$fixture/flake.lock")
(
  cd "$fixture"
  MOCK_NIX_MODE=nochange "$scripts_dir/update-flake-input" --dry-run foo >output
  grep -q 'No change' output
)
[[ $(checksum "$fixture/flake.lock") == "$before" ]] || die "flake no-change preview modified lock"
pass "flake dry-run reports no change without modifying the lock"
rm -rf "$fixture"
fixture=

new_fixture
printf '# dirty\n' >>"$fixture/flake.nix"
expect_failure "$fixture/output" bash -c "cd '$fixture' && '$scripts_dir/update-flake-input' foo"
grep -q 'tracked working copy is dirty' "$fixture/output" || die "flake dirty refusal was unclear"
pass "flake updater refuses a dirty tracked worktree"
rm -rf "$fixture"
fixture=

new_fixture
expect_failure "$fixture/output" bash -c "cd '$fixture' && '$scripts_dir/update-flake-input' missing"
grep -q 'not one explicit top-level input' "$fixture/output" || die "invalid input refusal was unclear"
pass "flake updater refuses an unknown top-level input"
rm -rf "$fixture"
fixture=

new_fixture
before=$(checksum "$fixture/flake.lock")
expect_failure "$fixture/output" bash -c "cd '$fixture' && MOCK_NIX_MODE=unrelated '$scripts_dir/update-flake-input' --apply foo"
[[ $(checksum "$fixture/flake.lock") == "$before" ]] || die "unrelated candidate modified flake.lock"
grep -q 'unrelated top-level input' "$fixture/output" || die "unrelated lock change was not identified"
pass "flake updater rejects unrelated candidate changes atomically"
rm -rf "$fixture"
fixture=

new_fixture
before=$(checksum "$fixture/flake.lock")
expect_failure "$fixture/output" bash -c "cd '$fixture' && MOCK_NIX_MODE=build-fail '$scripts_dir/update-flake-input' --apply foo"
[[ $(checksum "$fixture/flake.lock") == "$before" ]] || die "failed closure build modified flake.lock"
pass "flake updater leaves the lock unchanged when validation fails"
rm -rf "$fixture"
fixture=

new_fixture
(
  cd "$fixture"
  MOCK_NIX_MODE=change "$scripts_dir/update-flake-input" --apply foo >output
  [[ $(jq -r .nodes.foo.locked.rev flake.lock) == foo-new ]]
  [[ $(jq -r .nodes.bar.locked.rev flake.lock) == bar-old ]]
)
pass "flake updater applies only the validated input candidate"
rm -rf "$fixture"
fixture=

new_fixture
expect_failure "$fixture/output" bash -c "cd '$fixture' && '$scripts_dir/update-npm-tool' unknown 1.0.0"
grep -q 'unknown npm tool' "$fixture/output" || die "invalid npm package refusal was unclear"
pass "npm updater refuses an unknown package"
rm -rf "$fixture"
fixture=

new_fixture
before=$(checksum "$fixture/packages/external-tools.nix" "$fixture/packages/firstmate/lockfiles/gh-axi.package-lock.json")
(
  cd "$fixture"
  "$scripts_dir/update-npm-tool" --dry-run gh-axi 0.1.0 >output
  grep -q 'No change' output
)
[[ $(checksum "$fixture/packages/external-tools.nix" "$fixture/packages/firstmate/lockfiles/gh-axi.package-lock.json") == "$before" ]] || die "npm no-change preview modified files"
pass "npm dry-run reports no change without generation"
rm -rf "$fixture"
fixture=

new_fixture
printf '# dirty\n' >>"$fixture/packages/external-tools.nix"
expect_failure "$fixture/output" bash -c "cd '$fixture' && '$scripts_dir/update-npm-tool' gh-axi 0.1.0"
grep -q 'tracked working copy is dirty' "$fixture/output" || die "npm dirty refusal was unclear"
pass "npm updater refuses a dirty tracked worktree"
rm -rf "$fixture"
fixture=

new_fixture
before=$(checksum "$fixture/packages/external-tools.nix" "$fixture/packages/firstmate/lockfiles/gh-axi.package-lock.json")
expect_failure "$fixture/output" bash -c "cd '$fixture' && MOCK_NIX_MODE=build-fail '$scripts_dir/update-npm-tool' --apply gh-axi 0.2.0"
[[ $(checksum "$fixture/packages/external-tools.nix" "$fixture/packages/firstmate/lockfiles/gh-axi.package-lock.json") == "$before" ]] || die "failed npm build partially modified files"
pass "npm updater leaves metadata and lockfile unchanged when build fails"
rm -rf "$fixture"
fixture=

new_fixture
(
  cd "$fixture"
  "$scripts_dir/update-npm-tool" --apply gh-axi 0.2.0 >output
  grep -q 'version = "0.2.0"' packages/external-tools.nix
  [[ $(jq -r .version packages/firstmate/lockfiles/gh-axi.package-lock.json) == 0.2.0 ]]
  [[ -z $(git status --porcelain -- packages/pi-web/lockfiles/pi-web.package-lock.json) ]]
)
pass "npm updater applies only the selected validated stanza and lockfile"
rm -rf "$fixture"
fixture=

new_fixture
printf '# dirty\n' >>"$fixture/packages/external-tools.nix"
expect_failure "$fixture/output" bash -c "cd '$fixture' && '$scripts_dir/update-no-mistakes' 1.0.0"
grep -q 'tracked working copy is dirty' "$fixture/output" || die "Go dirty refusal was unclear"
pass "Go updater refuses a dirty tracked worktree"
rm -rf "$fixture"
fixture=

new_fixture
before=$(checksum "$fixture/packages/external-tools.nix")
(
  cd "$fixture"
  "$scripts_dir/update-no-mistakes" --dry-run 1.0.0 >output
  grep -q 'No change' output
)
[[ $(checksum "$fixture/packages/external-tools.nix") == "$before" ]] || die "Go no-change preview modified metadata"
pass "Go dry-run reports no change without generation"
rm -rf "$fixture"
fixture=

new_fixture
before=$(checksum "$fixture/packages/external-tools.nix")
expect_failure "$fixture/output" bash -c "cd '$fixture' && MOCK_NIX_NO_MISTAKES=1 MOCK_NIX_MODE=build-fail MOCK_NIX_COUNT='$fixture/count' '$scripts_dir/update-no-mistakes' --apply 1.53.0"
[[ $(checksum "$fixture/packages/external-tools.nix") == "$before" ]] || die "failed Go build modified metadata"
pass "Go updater leaves metadata unchanged when final build fails"
rm -rf "$fixture"
fixture=

new_fixture
(
  cd "$fixture"
  MOCK_NIX_NO_MISTAKES=1 MOCK_NIX_COUNT="$fixture/count" MOCK_NIX_OUT="$fixture/result" \
    "$scripts_dir/update-no-mistakes" --apply 1.53.0 >output
  grep -q 'version = "1.53.0"' packages/external-tools.nix
  grep -q 'rev = "f627beb7ffa8aceee353fb1deb88f40ae8611ad6"' packages/external-tools.nix
  grep -q 'vendorHash = "sha256-newvendor="' packages/external-tools.nix
  grep -q 'Validated: no-mistakes version v1.53.0' output
)
pass "Go updater applies consistent release metadata after binary verification"
rm -rf "$fixture"
fixture=

printf '1..%d\nAll update script behavior tests passed.\n' "$tests"
