#!/usr/bin/env python3
"""Write a categorized Markdown summary of package and flake input changes."""

import json
import re
import subprocess
import sys
from pathlib import Path


def git_file(revision: str, name: str) -> str:
    return subprocess.check_output(["git", "show", f"{revision}:{name}"], text=True)


def npm_versions(text: str) -> dict[str, str]:
    blocks = re.findall(
        r"(?ms)^\s*[A-Za-z0-9_-]+ = mkNpmTool \{(.*?)^\s*};", text
    )
    versions = {}
    for block in blocks:
        package = re.search(r'^\s*pname = "([^\"]+)";', block, re.M)
        version = re.search(r'^\s*version = "([^\"]+)";', block, re.M)
        if package and version:
            versions[package.group(1)] = version.group(1)
    return versions


def flake_inputs(text: str) -> dict[str, str]:
    lock = json.loads(text)
    result = {}
    for name, node in lock["nodes"].items():
        if name == "root":
            continue
        locked = node.get("locked", {})
        value = locked.get("version") or locked.get("ref") or locked.get("rev")
        if value:
            result[name] = str(value)
    return result


def entries(before: dict[str, str], after: dict[str, str]) -> list[str]:
    lines = []
    for name in sorted(before.keys() | after.keys()):
        old, new = before.get(name), after.get(name)
        if old == new:
            continue
        old = old or "(not present)"
        new = new or "(removed)"
        lines.append(f"- `{name}`: `{old}` → `{new}`")
    return lines


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: firstmate-update-summary.py BASE_REVISION OUTPUT_FILE")
    base, output = sys.argv[1:]
    files = {
        "Firstmate tools": (
            "packages/external-tools.nix",
            npm_versions,
        ),
        "Nix flake inputs": ("flake.lock", flake_inputs),
    }
    sections = ["Automated dependency update summary."]
    for heading, (path, parser) in files.items():
        old_values = parser(git_file(base, path))
        new_values = parser(Path(path).read_text())
        changes = entries(old_values, new_values)
        sections.extend(["", f"### {heading}", *(changes or ["- No changes."])])

    Path(output).write_text("\n".join(sections) + "\n")
    print(f"body_path={output}")


if __name__ == "__main__":
    main()
