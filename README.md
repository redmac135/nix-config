# nix-config

## Install

If it's the first time, you need to temporarily install git in the shell

```bash
nix-shell -p git
```

Then clone the repo and rebuild nixos

```bash
git clone https://github.com/redmac135/nix-config.git
cd nix-config
sudo nixos-rebuild switch --flake .#onhandwsl
sudo nixos-rebuild switch --flake .#pancakewsl
```

## Sync with config changes

If config changes, just rerun the rebuild

```bash
sudo nixos-rebuild switch --flake .#onhandwsl
sudo nixos-rebuild switch --flake .#pancakewsl
```

## Tailscale SSH

After switching a host, complete Tailscale authentication once if
`sudo tailscale status` reports `NeedsLogin`:

```bash
sudo tailscale up
sudo systemctl start tailscaled-set.service
```

The second command is safe to rerun and applies the declarative
`--ssh` preference. Connect using the host's MagicDNS name and the only
configured local account:

```bash
ssh ezhao@onhandwsl
ssh ezhao@pancakewsl
```

## Windows WezTerm and WSL

The tracked Windows templates are in `files/windows/`. They preserve the
current WezTerm setup: it opens the `WSL:NixOS` domain, starts in the WSL
`HOME`, and uses FiraCode Nerd Font with Catppuccin Mocha.

Install the WezTerm configuration from PowerShell by copying it to the Windows
user profile (the destination is `%USERPROFILE%\\.wezterm.lua`):

```powershell
Copy-Item .\\files\\windows\\.wezterm.lua $env:USERPROFILE\\.wezterm.lua
```

To keep it linked to this checkout instead, create a symbolic link from the
same destination. Run PowerShell with the permissions required for symlinks:

```powershell
New-Item -ItemType SymbolicLink `
  -Path $env:USERPROFILE\\.wezterm.lua `
  -Target (Resolve-Path .\\files\\windows\\.wezterm.lua)
```

Copy the WSL template to `%USERPROFILE%\\.wslconfig`:

```powershell
Copy-Item .\\files\\windows\\.wslconfig $env:USERPROFILE\\.wslconfig
```

After changing `.wslconfig`, restart WSL so it is re-read:

```powershell
wsl --shutdown
```

The template only enables localhost forwarding by default. The commented
`memory`, `processors`, and `swap` settings are optional machine-specific
limits; uncomment and adjust them for the Windows host. Ensure the WSL
installation is named `NixOS` (or change `config.default_domain` in the
WezTerm file to match it). The `HOME` working directory is resolved inside
WSL, not from a private Windows path.

## GitHub Copilot in Neovim

The Neovim configuration includes GitHub Copilot inline suggestions and
completion-menu results. After rebuilding, run `:Copilot auth` in Neovim to
sign in. Inline suggestions use these insert-mode keybindings:

- `Alt-l`: accept the suggestion
- `Alt-]`: show the next suggestion
- `Alt-[`: show the previous suggestion
- `Ctrl-]`: dismiss the suggestion

## Update packages

Update one flake input at a time and review the resulting lock change:

```bash
nix flake update <input>
git diff -- flake.lock
```

Build the configuration matching the native host before opening the update. CI
then builds both native closures before merge:

```bash
nix build -L --no-link '.#nixosConfigurations.onhandwsl.config.system.build.toplevel'
nix build -L --no-link '.#nixosConfigurations.pancakewsl.config.system.build.toplevel'
```

For manual updates, keep each flake input update in its own PR. In particular,
an `llm-agents` update can change Pi, Herdr, and OpenCode together, so review all
three selected versions. The automated bulk update described below is an
exception; review its combined changes carefully and split it if needed.

The custom npm tools in `packages/npm-packages.nix` are pinned separately.
Use the updater for a reviewable, transactional change. It refuses dirty or
ambiguous Git state, and preview is always side-effect free in the worktree:

```bash
# Inspect one package's latest release (no tracked files are changed)
./scripts/update-npm-packages --preview gh-axi
# Inspect an explicitly requested version
./scripts/update-npm-packages --preview gh-axi 0.1.29
# Apply one package after reviewing the preview
./scripts/update-npm-packages --apply gh-axi
# All packages is intentionally opt-in
./scripts/update-npm-packages --preview --all
./scripts/update-npm-packages --apply --all

git diff --check
git diff -- packages/npm-packages.nix packages/npm/lockfiles
```

The `Update npm packages, no-mistakes, and flake inputs` workflow runs weekly
on Monday at 10:30 UTC and can also be started manually. It runs the combined
updater and opens or updates a PR against `dev` only when the generated files
change. The updater refreshes npm packages, the `no-mistakes` release and Go
module hash, and the flake inputs:

```bash
./scripts/update-npm-packages-and-flake
```

The manual-install regression test checks the generated user environment:

```bash
./tests/mise-install.sh onhandwsl
./tests/mise-install.sh pancakewsl
```

The script downloads the published tarball, regenerates its vendored
`package-lock.json` with scripts disabled, and computes both Nix hashes. A
failed apply rolls back all files; review and commit the resulting diff
manually. The updater supports every package declared through `mkNpmTool` in
`packages/npm-packages.nix`, including `chrome-devtools-mcp`.

After review, validate both native closures and manually rebuild the matching
host:

```bash
nix build -L --no-link '.#nixosConfigurations.onhandwsl.config.system.build.toplevel'
nix build -L --no-link '.#nixosConfigurations.pancakewsl.config.system.build.toplevel'
sudo nixos-rebuild switch --flake .#onhandwsl
sudo nixos-rebuild switch --flake .#pancakewsl
```

### Toolchain ownership and pilot shell

Home Manager supplies Node.js 24 (including npm), Cargo and rustc from the
locked nixpkgs input, alongside rust-analyzer from the same package set. These
are the baseline, not fixed versions independent of `flake.lock`: updating that
lock changes them. The global mise config no longer selects Node or Rust. It
still selects Python, pnpm, bun, deno and Go; existing project-level mise
configuration remains active and can deliberately select its own Node or Rust.
Mise installations remain manual (`mise install`); no existing mise, rustup or
Cargo data is removed. The first rebuild after this change does not uninstall
those tools. `programs.nix-ld.enable` supports mise's prebuilt binaries, and the
build dependencies and GnuPG remain available for mise installations. Node and
Python mise downloads use prebuilt artifacts where available.

Mise's Zsh hook can place project tools ahead of the Nix profile, and an existing
`~/.cargo/bin` or other PATH entry can also win. Check `type -a node npm rustc
cargo rust-analyzer` and their `--version` output in the actual shell or editor
terminal; a Nix profile alone cannot guarantee precedence. For noninteractive
work, use the explicit pilot shell instead of relying on Zsh initialization:

```bash
nix develop .#toolchain -c node --version
nix develop .#toolchain -c cargo --version
# From a clean checkout, with network access:
nix develop .#toolchain -c ./scripts/update-npm-packages --preview gh-axi
```

This repository's npm package maintenance is the pilot: the shell uses the
repository's `flake.lock` for Node, Cargo, rustc and rust-analyzer, while the
vendored npm lockfiles and fixed hashes pin packaged dependencies separately.
The updater still needs Git, Python, Nix and network access; its npm registry
queries and `nixpkgs#prefetch-npm-deps` registry lookup are not pinned by this
shell. The shell can also be used as a starting point for Rust/Node projects, but a
project needs its own committed flake and language lockfiles to pin its own
versions. No automatic direnv integration is enabled. `nix develop -c` prepends
these Nix tools over inherited mise/rustup shims; starting an interactive Zsh
or running `mise exec` inside it can change PATH again. Start editors from the
shell and verify their LSP and compiler paths; external editors may use a
different environment. Native libraries, Rust targets, dependencies, caches,
and offline availability are project-specific and not guaranteed by this
pilot. Roll back the flake lock to a known-good commit to restore its package
selection; store availability and rooted generations still matter.

CI runs `tests/toolchain.sh` on both native architectures, including an offline
Rust build with competing shims on PATH, and tests project-specific mise Node
and global Python installation via `tests/mise-install.sh`. An
architecture-mismatched runner cannot validate the other host's profile.
If an interrupted rebuild leaves a transient unit loaded, stop it before retrying:

```bash
sudo systemctl stop nixos-rebuild-switch-to-configuration.service 2>/dev/null || true
sudo systemctl reset-failed nixos-rebuild-switch-to-configuration.service
sudo systemctl daemon-reload
```

`noMistakes` is packaged separately from the npm tools. The combined updater
above refreshes its release and Go module hashes; review those changes in
`packages/no-mistakes.nix`.

## Agent instructions

Home Manager exposes the shared `files/AGENTS.md` to all three agents without
copying it into project repositories:

- Claude Code imports `~/.AGENTS.md` from the user-level
  `~/.claude/CLAUDE.md`. A NixOS-managed setting selects
  `claude-md-and-agents-md`, so project `AGENTS.md` files load alongside
  project `CLAUDE.md` files instead of being silently skipped.
- Codex loads `~/.codex/AGENTS.md` as global guidance and combines it with
  project `AGENTS.md` files.
- Pi loads `~/.pi/agent/AGENTS.md` as user context alongside context files in
  the working directory and its parents.

Each tool uses its native instruction discovery, so project guidance remains
intact and later/more specific project instructions remain in the chain. No
project `AGENTS.md` is edited or duplicated. Claude Code v2.1.285 or later,
with its built-in AGENTS.md support enabled, is required to combine project
`AGENTS.md` and `CLAUDE.md`; older releases may not honor the managed setting.
Rebuild and switch the NixOS host (which activates integrated Home Manager),
then start new agent sessions. If `CODEX_HOME` or `PI_CODING_AGENT_DIR` is
customized, put the global instruction file in that configured directory too.

Sources: [Claude Code memory and instruction files](https://docs.anthropic.com/en/docs/claude-code/memory),
[Codex AGENTS.md discovery](https://developers.openai.com/codex/guides/agents-md),
and [Pi v1.2.0 configuration](https://github.com/earendil-works/pi/blob/v1.2.0/packages/coding-agent/docs/configuration.md).

## Pi configuration boundary

Home Manager installs Herdr's Pi lifecycle integration and the configured
`pi-web` package through their supported install commands. Pi records package
sources in `~/.pi/agent/settings.json`; the activation checks for `pi-web`
before installing it and leaves other package entries intact. Activation supplies
Nix-provided Node.js, npm, curl, and Pi on the installer PATH, independently of
mise and the interactive shell. Installing pi-web downloads its release and may
configure its user service. The Pi MCP adapter's global server overrides remain
in `~/.pi/agent/mcp.json`, and OAuth credentials are stored separately by the
adapter in the operating system
credential store. Home Manager does not declare either JSON file, so existing
manually managed packages and MCP servers are preserved.

To add Supabase outside this repository, first install the MCP adapter with
`pi install npm:pi-mcp-adapter` if needed, then merge this server into the
existing `mcpServers` object in `~/.pi/agent/mcp.json` without replacing other
servers:

```json
{
  "mcpServers": {
    "supabase": {
      "url": "https://mcp.supabase.com/mcp",
      "auth": "oauth"
    }
  }
}
```

Restart Pi and run `/mcp-auth supabase`. This uses Supabase's current official
remote endpoint and browser OAuth flow, so no access token, project reference,
or other secret is committed to this repository. See the
[Supabase MCP guide](https://supabase.com/docs/guides/getting-started/mcp).

## Clean Cache

```bash
# Delete generations older than 30 days
sudo nix profile wipe-history --older-than 30d

# Run the garbage collector
sudo nix-collect-garbage -d
```
