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

## Rust GUI apps on WSLg

For Cargo-built Wayland/wgpu apps that load libraries at runtime, enter the
opt-in GUI shell from the app's directory, replacing the path with this checkout:

```bash
nix develop /path/to/nix-config#gui
cargo run
```

The shell exposes the Wayland client and Vulkan loader via `LD_LIBRARY_PATH`.
This is scoped to the shell rather than all Nix applications. It does not start
a compositor or supply a Vulkan driver; WSLg and a working graphics driver are
still required. Run `./tests/gui-shell.sh` from this checkout to check the shell's
runtime library lookup.

If winit reports `WaylandError(Connection(NoCompositor))`, first inspect
`WAYLAND_DISPLAY` and `XDG_RUNTIME_DIR`, then check that the corresponding
socket accepts connections. A socket file or symlink existing is not enough:

```bash
printf 'WAYLAND_DISPLAY=%s XDG_RUNTIME_DIR=%s DISPLAY=%s\n' "${WAYLAND_DISPLAY-}" "${XDG_RUNTIME_DIR-}" "${DISPLAY-}"
python3 -c 'import os, socket; p = os.path.join(os.environ["XDG_RUNTIME_DIR"], os.environ["WAYLAND_DISPLAY"]); s = socket.socket(socket.AF_UNIX); s.connect(p); print("connected:", p)'
```

For the usual WSLg setup, the runtime socket points into
`/mnt/wslg/runtime-dir`. Check `/mnt/wslg/weston.log` for compositor startup
errors. For example, `failed to bind to /tmp/.X11-unix/X0: Address already in
use` can prevent WSLg startup even when the socket files remain. Do not delete
shared sockets blindly. WSLg runs on the Windows/WSL side: check that GUI apps
are enabled and WSL is up to date, and consider `wsl --shutdown` from Windows
only after stopping or saving work in all WSL distributions. A Windows-side
repair or restart may be needed; adding Linux packages alone cannot start WSLg.

In winit 0.30, a set `WAYLAND_DISPLAY` selects Wayland even if that connection
fails; `WINIT_UNIX_BACKEND` no longer selects the backend. An X11-only test can
unset `WAYLAND_DISPLAY` and `WAYLAND_SOCKET`, but requires a working X server
and its own runtime libraries. A missing Wayland library or Vulkan loader can
be masked until after the compositor socket is reachable.

## GitHub Copilot in Neovim

The Neovim configuration includes GitHub Copilot inline suggestions and
completion-menu results. After rebuilding, run `:Copilot auth` in Neovim to
sign in. Inline suggestions use these insert-mode keybindings:

- `Alt-l`: accept the inline suggestion, or the selected Copilot completion-menu result
- `Alt-]`: show the next suggestion
- `Alt-[`: show the previous suggestion
- `Ctrl-]`: dismiss the suggestion

Inline suggestions are hidden while the completion menu is open. Select a
Copilot result before pressing `Alt-l`, or close the menu to use an inline
suggestion. Other completion sources are not accepted by `Alt-l`.

## Rust in Neovim

After rebuilding and switching the host, run `mise install` to install the
configured Rust toolchain. The Nix-managed rust-analyzer uses the project's
Cargo toolchain on `PATH` for metadata and diagnostics. Install the standard
components if they are missing: `rustup component add rust-src rustfmt clippy`.
Run `cargo test` or `cargo clippy` in the project; rust-analyzer uses
`cargo check` for diagnostics. Cargo dependencies must be available for
project-wide analysis. Use `:checkhealth vim.lsp` and `cargo metadata` to
diagnose server or project loading issues.

Completion appears while typing, or use `Ctrl-Space`; `Tab` accepts a result.
Use `<leader>fm` to format Rust with rustfmt, and the existing LSP mappings for
code actions, definitions, and renaming.

For a representative Neovim regression test, run `./tests/nvim-open.sh onhandwsl`
(or `pancakewsl` on that host). It uses a pseudo-terminal and isolated home,
starts the real Rust language server against an offline Cargo fixture, checks
completion and rustfmt, and tests Copilot keybindings with a synthetic source.
It does not test external dependencies or the authenticated Copilot service.

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

The Firstmate npm tools are selected from the private `firstmate-nix` input.
Update their pins upstream, then update `firstmate-nix` here and review its
locked revision and selected versions. Local Git must have read access to that
repository. CI needs a fine-grained token with read-only Contents access to
`redmac135/firstmate-nix`, stored as the `FIRSTMATE_NIX_READ_TOKEN` repository
Actions secret. Do not grant broader repository access or commit the token.
The credential helper is scoped to that repository URL and enabled only in
steps that need the input. Only run these workflows on trusted branches: code
executed by a workflow can read its secrets. Fork PRs do not receive repository
secrets and cannot run these checks without a trusted maintainer-run build.

The `Update no-mistakes and flake inputs` workflow runs Mondays at 10:30 UTC
and can also be started manually. It opens or updates a PR against `dev` when
the generated files change:

```bash
./scripts/update-dependencies
```

The updater uses the GitHub releases API for no-mistakes. CI supplies its
built-in `GITHUB_TOKEN` for that API separately from the private-input token.
For local updates, optionally set `GITHUB_TOKEN` to a token with access to
public repositories to increase the API rate limit. If the limit is exhausted,
wait for it to reset; if authentication fails, check the token. `nix-update`
may prefer credentials in `~/.netrc` for github.com over `GITHUB_TOKEN`.

The manual-install regression test checks the generated user environment:

```bash
./tests/mise-install.sh onhandwsl
./tests/mise-install.sh pancakewsl
```

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
