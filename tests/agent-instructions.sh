#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

configuration=${1:-onhandwsl}
case $configuration in
  onhandwsl | pancakewsl) ;;
  *) echo "usage: $0 [onhandwsl|pancakewsl]" >&2; exit 2 ;;
esac

config=".nixosConfigurations.${configuration}.config"
home="${config}.home-manager.users.ezhao.home.file"
shared=$(nix eval --raw ".#${home}.\".AGENTS.md\".source")

for target in '.codex/AGENTS.md' '.pi/agent/AGENTS.md'; do
  source=$(nix eval --raw ".#${home}.\"${target}\".source")
  [[ $source == "$shared" ]]
  cmp -s files/AGENTS.md "$source"
done

claude_import=$(nix eval --raw ".#${home}.\".claude/CLAUDE.md\".text")
[[ $claude_import == '@~/.AGENTS.md' ]]

managed_settings=$(nix eval --raw ".#${config}.environment.etc.\"claude-code/managed-settings.json\".text")
printf '%s' "$managed_settings" |
  jq -e '.pluginConfigs["cc-plugin-agents-md@builtin"].options.instructionFiles == "claude-md-and-agents-md"' >/dev/null

echo 'agent instruction configuration tests passed'
