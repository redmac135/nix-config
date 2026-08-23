# nix-config

## Install

If it is the first time, temporarily install Git, clone the repository, and
build the configuration for that host:

```bash
nix-shell -p git
git clone https://github.com/redmac135/nix-config.git
cd nix-config
nix build --no-link '.#nixosConfigurations.surface.config.system.build.toplevel'
sudo nixos-rebuild dry-activate --flake '.#surface'
sudo nixos-rebuild switch --flake '.#surface'
```

Use `desktop` instead of `surface` on the desktop host.

## Apply configuration changes

Preview every host switch. Apply and verify one host before moving to the other:

```bash
host=surface # or desktop
nix build --no-link ".#nixosConfigurations.$host.config.system.build.toplevel"
sudo nixos-rebuild dry-activate --flake ".#$host"
sudo nixos-rebuild switch --flake ".#$host"
```

Keep the previous NixOS generations until both hosts have been switched and
verified. Do not garbage-collect a known-good generation during rollout.

## Safe targeted updates

Routine updates are one component per invocation and one component per PR.
Each updater defaults to a preview: it generates the candidate in temporary
space, prints focused old/new evidence, and builds the affected native output
without changing tracked files. After review, re-run with `--apply`; generation
and validation are repeated before the candidate is applied.

### One flake input

```bash
scripts/update-flake-input llm-agents
scripts/update-flake-input --apply llm-agents
```

The command accepts only one explicit top-level input, uses Nix's candidate and
reference lock mechanisms, rejects changes outside the selected dependency
closure, and builds the native host closure before atomically replacing
`flake.lock`. Never use a bare `nix flake update` for routine maintenance. An
`llm-agents` revision can change Pi, Herdr, and OpenCode together, so inspect all
three selected versions in its PR.

### One npm tool

```bash
scripts/update-npm-tool gh-axi 0.1.33
scripts/update-npm-tool --apply gh-axi 0.1.33
```

Accepted names are the five `*-axi` tools and `pi-web`. The command verifies the
published immutable tarball, regenerates the vendored lockfile without lifecycle
scripts, computes both Nix hashes, and builds only the selected package.
`pi-web` automatically repairs the nested shrinkwrap integrity omissions and
uses npm dependency fetcher v2. This flow changes one npm stanza and one matching
lockfile; it is intentionally separate from the Go updater.

### no-mistakes (Go)

```bash
scripts/update-no-mistakes 1.53.0
scripts/update-no-mistakes --apply 1.53.0
```

The command requires an exact stable GitHub release, resolves its immutable
commit and date, computes source and Go vendor hashes, updates release ldflags,
builds the package, and verifies `no-mistakes --version`. There is no npm
lockfile or `npmDepsHash` in this Go flow.

### Review, CI, and rollout

For every component:

1. Start with a clean tracked worktree and generate exactly one preview.
2. Review the printed version, revision, hash, lock/diff, and native build
   evidence. Run the updater with `--apply` only after that preview is accepted.
3. Commit only that component and open one PR. Do not bundle another input or
   tool update.
4. Require the existing CI matrix to build both complete native closures:
   `desktop` on x86_64 and `surface` on aarch64. Evaluation alone is not a gate.
5. After merge, build, `nixos-rebuild dry-activate`, switch, and verify one host
   at a time as shown above. Retain previous generations until both pass.

Run the observable updater tests with:

```bash
scripts/tests/update-scripts.sh
```

## Clean cache

Only clean old generations after both hosts are verified and no retained
rollback generation is needed:

```bash
sudo nix profile wipe-history --older-than 30d
sudo nix-collect-garbage -d
```
