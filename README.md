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
sudo nixos-rebuild switch --flake .#surface
sudo nixos-rebuild switch --flake .#desktop
```

## Sync with config changes

If config changes, just rerun the rebuild

```bash
sudo nixos-rebuild switch --flake .#surface
sudo nixos-rebuild switch --flake .#desktop
```

## Update packages

Update one flake input at a time and review the resulting lock change:

```bash
nix flake update <input>
git diff -- flake.lock
```

Build the configuration matching the native host before opening the update. CI
then builds both native closures before merge:

```bash
nix build -L --no-link '.#nixosConfigurations.surface.config.system.build.toplevel'
nix build -L --no-link '.#nixosConfigurations.desktop.config.system.build.toplevel'
```

Keep each flake input update in its own PR. In particular, an `llm-agents`
update can change Pi, Herdr, and OpenCode together, so review all three selected
versions.

The custom npm tools in `packages/external-tools.nix` are pinned separately. To
bump one, generate its vendored `package-lock.json` with
`npm install --package-lock-only --ignore-scripts`, replace the matching lockfile
under `packages/firstmate/lockfiles/`, and update its `version`, `tarballHash`,
and `npmDepsHash` in `packages/external-tools.nix`.
Update one tool per PR.

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
