#!/usr/bin/env bash
set -euo pipefail

root=$(dirname "$(dirname "$(realpath "$0")")")
python=$(command -v python3)
sentinel=/nonexistent/gui-shell-preserved

check_shell() {
  nix develop "$root#gui" --command "$python" -c '
import ctypes
import os

paths = os.environ["LD_LIBRARY_PATH"].split(":")
assert all(paths), paths
if sentinel := os.environ.get("GUI_SHELL_SENTINEL"):
    assert paths[-1] == sentinel, paths
for library in ("libwayland-client.so.0", "libvulkan.so.1"):
    ctypes.CDLL(library)
    print("loaded", library)
'
}

unset LD_LIBRARY_PATH GUI_SHELL_SENTINEL
check_shell
export LD_LIBRARY_PATH="$sentinel" GUI_SHELL_SENTINEL="$sentinel"
check_shell
