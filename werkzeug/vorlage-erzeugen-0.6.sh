#!/bin/bash
# Symbole 0.6: erzeugt integration/vorlage-0.6 für symbole-integrieren-0.6.sh
# und trägt SUMMEN_SHA dort ein. Inhalt:
#   neu/<Stufe>/apps/org.querencia.Dokumente.{png,svg}
#       aus quellen/org.querencia.Dokumente.svg (werkzeug/rendern.py),
#       16/22/24/32/64/128/256 + scalable, nie 48x48
#   dokumente-0.1.0/<Stufe>/apps/…
#       byte-gleiche Kopie der Symbole aus Tag dokumente/0.1.0 von
#       querencia-dokumente, data/icons/hicolor (das, was dessen Skript in
#       hicolor ablegt; geprüft gegen die SHA256SUMS seiner Vorlage im Tag)
#   SHA256SUMS über beide Ordner
# Prüft: zweimal gerendert gleich; das ganze Thema aus quellen/thema/namen.txt
# gebaut (werkzeug/thema-bauen.py) ist die eingefrorene Thema-Vorlage 0.1
# plus genau diese acht Dateien, byte-gleich. Die Thema-Vorlage und
# integration/vorlage bleiben unberührt (Rückfallpfade von 0.5.2 und Thema).
# Verweigert, sobald das Journal die 0.6-Datei nennt (nach einer Aktivierung
# entstehen neue Fassungen nur in neuen Dateien).
# Aufruf: bash vorlage-erzeugen-0.6.sh   (liest live nur das Journal)
set -euo pipefail
R=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
I=$R/integration
V=$I/vorlage-0.6
SKRIPT=$I/symbole-integrieren-0.6.sh
DOK_REPO=~/projects/querencia-dokumente
DOK_TAG=dokumente/0.1.0
NAME=org.querencia.Dokumente
STUFEN="16x16 22x22 24x24 32x32 64x64 128x128 256x256"
if grep -q 'symbole-integrieren-0\.6\.sh' ~/opt/querencia/protokoll.txt 2>/dev/null; then
    echo "Das Journal nennt symbole-integrieren-0.6.sh – Vorlage eingefroren, neue Fassung als eigene Datei" >&2
    exit 1
fi
TMP=$(mktemp -d)
trap 'chmod -R u+w "$TMP"; rm -rf -- "$TMP"' EXIT

python3 -I "$R/werkzeug/rendern.py" "$R/quellen" "$TMP/a" "$NAME" >/dev/null
python3 -I "$R/werkzeug/rendern.py" "$R/quellen" "$TMP/b" "$NAME" >/dev/null
diff -r "$TMP/a" "$TMP/b" >/dev/null || { echo "Rendern nicht reproduzierbar" >&2; exit 1; }
[ "$(find "$TMP/a" -type f | wc -l)" = 8 ] && [ ! -e "$TMP/a/icons/hicolor/48x48" ]

# Thema: eingefrorene Vorlage 0.1 + genau die acht neuen Dateien
python3 -I "$R/werkzeug/thema-bauen.py" "$R/quellen" "$TMP/t" >/dev/null
liste() { (cd "$1" && find . -type f -exec sha256sum {} + | sed 's#  \./#  #' | LC_ALL=C sort); }
diff <(liste "$I/thema/vorlage/Querencia") <(liste "$TMP/t/Querencia" | grep -v "/apps/$NAME\.") >/dev/null ||
    { echo "Thema aus namen.txt weicht außer $NAME von der Thema-Vorlage 0.1 ab" >&2; exit 1; }
[ "$(liste "$TMP/t/Querencia" | grep -c "/apps/$NAME\.")" = 8 ]
for g in $STUFEN scalable; do
    [ "$g" = scalable ] && f=$g/apps/$NAME.svg || f=$g/apps/$NAME.png
    cmp "$TMP/a/icons/hicolor/$f" "$TMP/t/Querencia/$f"
done

# Symbole von Dokumente 0.1.0 aus dem Tag (data/icons), geprüft gegen die im
# Tag eingecheckte integration/vorlage/SHA256SUMS (= was dessen Skript ablegt)
mkdir -p "$TMP/dok"
git -C "$DOK_REPO" archive "$DOK_TAG" data/icons/hicolor integration/vorlage/SHA256SUMS | tar -x -C "$TMP/dok" -f -
[ "$(find "$TMP/dok/data/icons/hicolor" -type f | wc -l)" = 8 ]
grep '  \./icons/hicolor/' "$TMP/dok/integration/vorlage/SHA256SUMS" | sed 's#  \./icons/#  data/icons/#' >"$TMP/dok/icons.sha256"
[ "$(wc -l <"$TMP/dok/icons.sha256")" = 8 ]
(cd "$TMP/dok" && sha256sum -c --quiet icons.sha256)

[ ! -e "$V" ] || chmod -R u+w "$V"
rm -rf -- "$V"
mkdir -p "$V"
cp -r "$TMP/a/icons/hicolor" "$V/neu"
cp -r "$TMP/dok/data/icons/hicolor" "$V/dokumente-0.1.0"
find "$V" -type d -exec chmod 0755 {} +
find "$V" -type f -exec chmod 0644 {} +
(cd "$V" && find neu dokumente-0.1.0 -type f | LC_ALL=C sort | xargs sha256sum >SHA256SUMS)
chmod -R a-w "$V"
summe=$(sha256sum "$V/SHA256SUMS" | cut -d' ' -f1)
sed -i "s/^SUMMEN_SHA=.*/SUMMEN_SHA=$summe/" "$SKRIPT"
echo "SUMMEN_SHA=$summe (eingetragen in $SKRIPT); $(find "$V" -type f | wc -l) Dateien"
