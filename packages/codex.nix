{
  pkgs,
  codex,
}:
pkgs.runCommand "codex-${codex.version}-package" {
  pname = "codex";
  version = codex.version;
  inherit (codex) meta;
  nativeBuildInputs = [pkgs.makeWrapper];
} ''
    mkdir -p "$out"
    cp -R ${codex}/. "$out/"
    chmod -R u+w "$out"

    package="$out/libexec/codex"
    mkdir -p "$package/codex-path"
    rm "$package/codex-resources/bwrap"
    cp ${pkgs.bubblewrap}/bin/bwrap "$package/codex-resources/bwrap"
    cp ${pkgs.ripgrep}/bin/rg "$package/codex-path/rg"

    cat > "$package/codex-package.json" <<'EOF'
  {
    "layoutVersion": 1,
    "version": "${codex.version}",
    "target": "${pkgs.stdenv.hostPlatform.config}",
    "variant": "codex",
    "entrypoint": "bin/codex",
    "resourcesDir": "codex-resources",
    "pathDir": "codex-path"
  }
  EOF

    rm "$out/bin/codex"
    makeWrapper "$package/bin/codex" "$out/bin/codex" \
      --prefix PATH : ${pkgs.lib.makeBinPath [pkgs.bubblewrap]}
''
