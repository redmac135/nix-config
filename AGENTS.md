# Project agent memory

This file is the project's committed home for project-intrinsic agent knowledge: build, test, release, architecture, and sharp-edge notes that should travel with the code.

- Add durable project-specific notes here as they are discovered through real work.

## Packaging firstmate CLIs

`packages/firstmate.nix` builds the kunchenguid firstmate tools (`no-mistakes` + the five `*-axi` npm CLIs) as Nix derivations, exposed as the `pkgs.firstmate` overlay.

- `no-mistakes` is `pkgs.buildGoModule` from the pinned GitHub tag; `subPackages = ["cmd/no-mistakes"]` is required (root package is test-only).
- Each `*-axi` is `pkgs.buildNpmPackage` from the immutable npm registry tarball (prebuilt `dist/`; `dontNpmBuild = true`). To bump one, regenerate its lockfile with `npm install --package-lock-only --ignore-scripts` on the extracted tarball, replace `packages/firstmate/lockfiles/<pkg>.package-lock.json`, and update `version`, `tarballHash`, `npmDepsHash` (obtainable from the FOD hash-mismatch error, or `nix run nixpkgs#prefetch-npm-deps`).

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
