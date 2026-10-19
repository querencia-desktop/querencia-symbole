#!/bin/bash
# Thema-2: erzeugt integration/vorlage für symbole-integrieren.sh 0.3 neu
# (G2-V-Symbole plus Files, Strata-Kopie, Terminal, Screenshot) und
# integration/SHA256SUMS. integration/ausgang bleibt der Stand vom 19.10.2026
# ~10:00 (wird nicht neu vom Live-Stand gelesen; die neuen Namen fehlen dort).
# Prüft: die sechs G2-V-Symbole und der Referenz-Starter sind byte-gleich mit
# der Vorlage 0.2 (Tag symbole/0.2), kein 48x48, die neuen Namen liegen live
# nicht in hicolor. Danach SUMMEN_SHA in symbole-integrieren.sh eintragen.
# Aufruf: bash vorlage-erzeugen-0.3.sh   (im Worktree, liest live nur)
set -euo pipefail
R=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
I=$R/integration
ICONS_LIVE=~/.local/share/icons
ALT="org.querencia.Systemmonitor org.querencia.Einstellungen org.querencia.Editor org.querencia.Bilder org.querencia.Sitzung org.querencia.Lautstaerke"
NEU="org.querencia.Files org.querencia.Terminal org.querencia.Screenshot"
GROESSEN="16x16 22x22 24x24 32x32 64x64 128x128 256x256"
TMP=$(mktemp -d)
trap 'chmod -R u+w "$TMP"; rm -rf -- "$TMP"' EXIT

# Vorlage 0.2 aus dem Tag, zum Vergleich
git -C "$R" archive symbole/0.2 integration/vorlage integration/ausgang integration/SHA256SUMS | tar -x -C "$TMP"
diff -r "$TMP/integration/ausgang" "$I/ausgang" >/dev/null || { echo "ausgang/ weicht vom Tag symbole/0.2 ab" >&2; exit 1; }

chmod -R u+w "$I/vorlage" 2>/dev/null || true
rm -rf -- "$I/vorlage"
mkdir -p "$I/vorlage/applications"
cp -p "$TMP/integration/vorlage/applications/org.querencia.Einstellungen.desktop" "$I/vorlage/applications/"
# shellcheck disable=SC2086
python3 -I "$R/werkzeug/rendern.py" "$R/quellen" "$I/vorlage" $ALT $NEU
# Übergang: dieselben Dateien unter dem Namen des heutigen Files-Starters
for g in $GROESSEN; do
    cp -p "$I/vorlage/icons/hicolor/$g/apps/org.querencia.Files.png" "$I/vorlage/icons/hicolor/$g/apps/io.github.lgse.Strata.png"
done
cp -p "$I/vorlage/icons/hicolor/scalable/apps/org.querencia.Files.svg" "$I/vorlage/icons/hicolor/scalable/apps/io.github.lgse.Strata.svg"

# G2-V-Teil muss byte-gleich mit 0.2 sein (sonst wäre der Live-Stand „fremd“)
for n in $ALT; do
    for g in $GROESSEN scalable; do
        [ "$g" = scalable ] && f=icons/hicolor/$g/apps/$n.svg || f=icons/hicolor/$g/apps/$n.png
        cmp "$TMP/integration/vorlage/$f" "$I/vorlage/$f"
    done
done
[ ! -e "$I/vorlage/icons/hicolor/48x48" ]
for n in $NEU io.github.lgse.Strata; do
    [ -z "$(find "$ICONS_LIVE/hicolor" -name "$n.*" -print -quit)" ] || { echo "$n liegt schon live in hicolor" >&2; exit 1; }
done
(cd "$I" && find vorlage ausgang -type f | LC_ALL=C sort | xargs sha256sum >SHA256SUMS)
chmod -R a-w "$I/vorlage" "$I/ausgang"
echo "SUMMEN_SHA=$(sha256sum "$I/SHA256SUMS" | cut -d' ' -f1)"
echo "Vorlage: $(find "$I/vorlage" -type f | wc -l) Dateien, Ausgang: $(find "$I/ausgang" -type f | wc -l) Dateien"
