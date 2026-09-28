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

The custom npm tools in `packages/external-tools.nix` are pinned separately.
Use the updater for a reviewable, transactional change. It refuses dirty or
ambiguous Git state, and preview is always side-effect free in the worktree:

```bash
# Inspect one package's latest release (no tracked files are changed)
./scripts/update-firstmate-tools --preview gh-axi
# Inspect an explicitly requested version
./scripts/update-firstmate-tools --preview gh-axi 0.1.29
# Apply one package after reviewing the preview
./scripts/update-firstmate-tools --apply gh-axi
# All packages is intentionally opt-in
./scripts/update-firstmate-tools --preview --all
./scripts/update-firstmate-tools --apply --all

git diff --check
git diff -- packages/external-tools.nix packages/firstmate/lockfiles
```

The script downloads the published tarball, regenerates its vendored
`package-lock.json` with scripts disabled, and computes both Nix hashes. A
failed apply rolls back all files; review and commit the resulting diff
manually. The updater is limited to the `*-axi` packages declared by
`packages/external-tools.nix`.

After review, validate both native closures and manually rebuild the matching
host:

```bash
nix build -L --no-link '.#nixosConfigurations.onhandwsl.config.system.build.toplevel'
nix build -L --no-link '.#nixosConfigurations.pancakewsl.config.system.build.toplevel'
sudo nixos-rebuild switch --flake .#onhandwsl
sudo nixos-rebuild switch --flake .#pancakewsl
```

Home Manager activation runs `mise install --yes` as `ezhao`, with the global
config pinned in `MISE_CONFIG_FILE`, after writing
`~/.config/mise/config.toml`. `programs.nix-ld.enable` supplies the
linker for mise's upstream Node.js and Python binaries; `gcc`, `gnumake`, and
`pkg-config` are the minimal native build tools retained for a source-build
fallback.

`firstmate.no-mistakes` is a separate Go package. Update its exact release tag,
source hash, `vendorHash`, and release `ldflags` independently from npm and flake
input updates.

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
