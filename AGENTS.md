# Project agent memory

This file is the project's committed home for project-intrinsic agent knowledge: build, test, release, architecture, and sharp-edge notes that should travel with the code.

- Add durable project-specific notes here as they are discovered through real work.

## Repository scope

This is a Nix-only repository: do not add JavaScript code or dependencies, or configure project-local Prettier/ESLint checks.

## Updating flake inputs

Update one input per PR with `nix flake update <input>`, review `flake.lock`, and build the native no-link closure before pushing; `.github/workflows/evaluate.yml` gates both native host closures. An `llm-agents` update can change Pi, Herdr, and OpenCode together, so inspect all three selected versions.

## Packaging npm tools

`packages/npm-packages.nix` builds pinned npm packages exposed under `pkgs.npmPkgs`; the Go `no-mistakes` derivation is in `packages/no-mistakes.nix`.

- Use `scripts/update-npm-packages` to preview or apply version and lockfile updates for any package declared through `mkNpmTool`.

## Neovim organization

Keep the Neovim configuration minimal and modern: general plugin setup belongs in `nvim/lua/config/plugins/`, native `nvim/after/`, `nvim/before/`, and `nvim/ftplugin/` layouts hold scoped overrides, and all keymaps belong in `nvim/lua/config/keymaps.lua`. The authoritative module load order is `nvim/init.lua`.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
