#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
fixture="$root/tests/fixtures/image-preview.png"

for command in magick identify; do
  command -v "$command" >/dev/null || {
    printf 'missing %s; rebuild the Home Manager configuration first\n' "$command" >&2
    exit 1
  }
done

[[ "$(identify -format '%m %wx%h' "$fixture")" == "PNG 1x1" ]]
magick "$fixture" -format '%m %wx%h' info: | grep -qx 'PNG 1x1'

grep -q 'image = {' "$root/nvim/lua/config/plugins/snacks.lua"
grep -q 'enabled = true' "$root/nvim/lua/config/plugins/snacks.lua"
grep -q 'imagemagick' "$root/home.nix"

XDG_CONFIG_HOME="$root" SNACKS_WEZTERM=true \
  NIX_IMAGE_FIXTURE="$fixture" \
  NIX_TEXT_FIXTURE="$root/tests/fixtures/text-preview.txt" \
  nvim --headless -u "$root/nvim/init.lua" \
  -l "$root/tests/image-preview.lua"
