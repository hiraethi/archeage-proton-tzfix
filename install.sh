#!/bin/sh
# Installs proton-cachyos-tzfix: a copy of proton-cachyos 11.0-20261015 with
# patched kernel32.dll and kernelbase.dll. The original Proton is not modified.
set -eu

WANT="cachyos-11.0-20261015"
NAME="proton-cachyos-tzfix"
HERE=$(cd "$(dirname "$0")" && pwd)
DEST_ROOT="${STEAM_COMPAT_TOOLS:-$HOME/.local/share/Steam/compatibilitytools.d}"
DEST="$DEST_ROOT/$NAME"

die() { echo "error: $*" >&2; exit 1; }

(cd "$HERE" && sha256sum -c --quiet SHA256SUMS) || die "DLL checksums do not match SHA256SUMS"

SRC=""
for dir in /usr/share/steam/compatibilitytools.d/* \
           "$HOME"/.local/share/Steam/compatibilitytools.d/* \
           "$HOME"/.steam/root/compatibilitytools.d/* \
           "$HOME"/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d/*; do
    [ -f "$dir/version" ] && [ -f "$dir/proton" ] || continue
    [ "$(basename "$dir")" = "$NAME" ] && continue
    if grep -q "$WANT" "$dir/version"; then SRC=$dir; break; fi
done
[ -n "$SRC" ] || die "proton-cachyos $WANT not found. Install that exact version first."

[ -e "$DEST" ] && die "$DEST already exists. Remove it to reinstall."

trap 'rm -rf "$DEST"' EXIT    # no half-installed tool on failure
echo "Copying $SRC"
echo "     to $DEST"
mkdir -p "$DEST_ROOT"
cp -a "$SRC" "$DEST"
chmod -R u+w "$DEST"

for arch in x86_64 i386; do
    for dll in kernel32 kernelbase; do
        target="$DEST/files/lib/wine/$arch-windows/$dll.dll"
        [ -f "$target" ] || die "unexpected Proton layout: $target missing"
        cp "$HERE/dlls/$arch-windows/$dll.dll" "$target"
    done
done

# the internal name line can carry a trailing // comment
sed -i -E "0,/^    \"[^\"]*\"[[:space:]]*(\/\/.*)?$/s//    \"$NAME\"/; s/\"display_name\" \"[^\"]*\"/\"display_name\" \"$NAME (time-zone fix)\"/" \
    "$DEST/compatibilitytool.vdf"
# a different version string makes Proton relink the game prefix to these DLLs
echo "$(cut -d' ' -f1 "$SRC/version") $WANT-tzfix" > "$DEST/version"

grep -q "\"$NAME\"" "$DEST/compatibilitytool.vdf" || die "could not rename the tool in compatibilitytool.vdf"
trap - EXIT
echo "Done. Restart Steam, then pick \"$NAME (time-zone fix)\" under"
echo "ArcheAge Chronicles > Properties > Compatibility."
