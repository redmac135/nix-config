#!/usr/bin/env bash
set -euo pipefail

root=$(dirname "$(dirname "$(realpath "$0")")")
case $(uname -m) in
  aarch64) configuration=onhandwsl ;;
  x86_64) configuration=pancakewsl ;;
  *) echo "unsupported host architecture: $(uname -m)" >&2; exit 2 ;;
esac
# Use the same Nixpkgs glibc as the runtime libraries, not the host's Python.
python="$(nix build --no-link --print-out-paths "$root#nixosConfigurations.$configuration.pkgs.python3")/bin/python3"
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
