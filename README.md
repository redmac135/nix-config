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

Keep each flake input update in its own PR. In particular, an `llm-agents`
update can change Pi, Herdr, and OpenCode together, so review all three selected
versions.

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

The `Update npm packages, no-mistakes, and flake inputs` workflow runs daily at
5:30 AM EST and can also be started manually. It runs the combined updater and
opens or updates a PR against `dev` only when the generated files change. The
updater refreshes npm packages, the `no-mistakes` release and Go module hash,
and the flake inputs:

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

Mise tools are installed manually with `mise install` after switching. `programs.nix-ld.enable`
supplies the linker for mise's upstream Node.js and Python binaries. `python3`
supplies the `python` configure command, `gcc` and `gnumake` compile source
fallbacks, `pkg-config` and `zlib.dev` provide build metadata and headers,
`openssl.dev` provides TLS headers, and `gnupg` verifies released tool archives.
The global mise config pins Node.js 24 and explicitly selects prebuilt Node.js
and Python artifacts; without those settings, mise selected aarch64 source
archives and spent minutes compiling Node. Its bundled npm is validated by
`tests/mise-install.sh`. CI builds both host closures and runs the bounded
manual Node.js, npm, and Python mise install on each native runner; an
architecture-mismatched runner cannot build the other host's profile.
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

## Pi MCP configuration boundary

This flake installs Pi, but it does not own Pi's mutable package or MCP files.
Pi packages remain in `~/.pi/agent/settings.json`, while the Pi MCP adapter's
global server overrides remain in `~/.pi/agent/mcp.json`. OAuth credentials are
stored separately by the adapter in the operating system credential store.
Home Manager must not declare either JSON file without first migrating all of
its existing entries, because doing so would replace manually managed packages
or MCP servers.

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
