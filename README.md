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

## HTN26 QNX-sidecar model runtime

The Home Manager Python 3.12 environment includes NumPy and OpenCV's Python
bindings. Apply the configuration for the laptop (`onhandwsl`), start a new
shell, and verify both imports:

```bash
sudo nixos-rebuild switch --flake .#onhandwsl
python -c 'import cv2, numpy'
```

In nixpkgs, the package is named `opencv4`, while Python imports it as `cv2`.
The OpenCV and NumPy versions come from the nixpkgs revision pinned in
`flake.lock`; they are intentionally not upgraded or pinned independently.

## Neovim image previews

Neovim enables Snacks image previews for the supported Kitty graphics protocol.
On WSL, use Neovim inside WezTerm and rebuild Home Manager so ImageMagick's
`magick` and `identify` commands are available:

```bash
sudo nixos-rebuild switch --flake .#onhandwsl
nvim path/to/image.png
```

Snacks' picker preview (`<space>ff`) and direct image opening use the same
image buffer path; normal text files continue to open as text. WezTerm has a
known limitation: Snacks cannot render inline document images there, so this
configuration uses the floating image view instead. Run `:checkhealth snacks`
inside Neovim if terminal capability detection fails.

## GitHub Copilot in Neovim

The Neovim configuration includes GitHub Copilot inline suggestions and
completion-menu results. After rebuilding, run `:Copilot auth` in Neovim to
sign in. Inline suggestions use these insert-mode keybindings:

- `Alt-l`: accept the suggestion
- `Alt-]`: show the next suggestion
- `Alt-[`: show the previous suggestion
- `Ctrl-]`: dismiss the suggestion

## Neovim image previews

Press `<leader>iv` while the cursor is on an image in Oil (or while its file
buffer is active) to open an ANSI preview in a Snacks floating terminal. The
configuration uses `chafa`, declared in `home.nix`, so it works in WSL through
Windows Terminal without requiring a graphics protocol.

Snacks' native image module uses the Kitty Graphics Protocol, which Windows
Terminal does not provide to WSL, so it is intentionally not enabled here.
`chafa` degrades to a normal notification when it is unavailable or the
selected path cannot be read. Rebuild Home Manager after installation:

```bash
sudo nixos-rebuild switch --flake .#pancakewsl
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
nix build -L --no-link '.#nixosConfigurations.onhandwsl.config.system.build.toplevel'
nix build -L --no-link '.#nixosConfigurations.pancakewsl.config.system.build.toplevel'
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
