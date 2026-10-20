#!/bin/bash
# Symbole 0.7: erzeugt den Arbeitsordner der Integration (Vorgabe
# ~/projects/querencia-symbole-07/integration) aus diesem Repo:
#   vorlage/neu/Querencia  das ganze Thema aus quellen/thema/namen.txt
#                          (werkzeug/thema-bauen.py, zweimal gebaut, gleich)
#   vorlage/alt/Querencia  Stand 0.6 = eingefrorene Thema-Vorlage 0.1
#                          (integration/thema/vorlage) + die 8 Dateien
#                          org.querencia.Dokumente aus integration/vorlage-0.6/neu
#   vorlage/SHA256SUMS     über alt und neu
#   symbole-07-integrieren.sh  aus integration/symbole-07/*.sh.in mit
#                          eingetragenem SUMMEN_SHA (0555)
#   AENDERUNG.txt          welche Dateien 0.7 setzt (neu oder ersetzt)
# Prüft: Bau reproduzierbar, keine 48x48; Thema- und 0.6-Vorlage gegen ihre
# im Skript eingetragenen Prüfsummen; neu = alt + genau die erwarteten
# Namen (user-desktop ersetzt; user-desktop-symbolic, show-desktop,
# show-desktop-symbolic und fünf Programme neu;
# nichts entfernt); index.theme unverändert; Programmsymbole byte-gleich mit
# quellen/thema/programme/HERKUNFT.txt.
# Verweigert, sobald das Journal symbole-07-integrieren.sh nennt (nach einer
# Aktivierung entstehen neue Fassungen nur in neuen Dateien).
# Aufruf: bash vorlage-erzeugen-0.7.sh [<arbeitsordner>]   (liest live nur das Journal)
set -euo pipefail
R=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
I=$R/integration
ARBEIT=${1:-~/projects/querencia-symbole-07}
Z=$ARBEIT/integration
V=$Z/vorlage
SKRIPT=$Z/symbole-07-integrieren.sh
THEMA_SUMMEN_SHA=5f609c282cfb6da12209669beab59ff12f556ab1d69fbe3cd4e75bc35b511171
V06_SUMMEN_SHA=32c1e543be7a1f26fc3d2c64b8c20e14482a618317d8e5a16b36aeb320f8edb0
STUFEN="16x16 22x22 24x24 32x32 64x64 128x128 256x256"
ERSETZT="places/user-desktop"
NEU="places/user-desktop-symbolic places/show-desktop places/show-desktop-symbolic apps/org.querencia.Archiv apps/org.querencia.Software apps/org.querencia.Dateisuche apps/org.querencia.Rechner apps/org.querencia.Kuerzel"
KNOPF="user-desktop und user-desktop-symbolic, Alias show-desktop"
KNOPF_JOURNAL="user-desktop neu (Arbeitsfläche mit Leiste und minimierten Fenstern: Panel-Knopf Arbeitsfläche anzeigen und Ordner Arbeitsfläche), user-desktop-symbolic, Alias show-desktop(-symbolic)"

if grep -q 'symbole-07-integrieren\.sh' ~/opt/querencia/protokoll.txt 2>/dev/null; then
    echo "Das Journal nennt symbole-07-integrieren.sh – Vorlage eingefroren, neue Fassung als eigene Datei" >&2
    exit 1
fi
TMP=$(mktemp -d)
trap 'chmod -R u+w "$TMP"; rm -rf -- "$TMP"' EXIT
liste() { (cd "$1" && find . -type f -exec sha256sum {} + | sed 's#  \./#  #' | LC_ALL=C sort); }
dateien_von() { # <kontext/name> → relative Pfade (8 Dateien, -symbolic nur das SVG)
    local g k=${1%%/*} n=${1#*/}
    case $n in *-symbolic) ;; *) for g in $STUFEN; do echo "$g/$k/$n.png"; done ;; esac
    echo "scalable/$k/$n.svg"
}

# Herkunft der Programmsymbole
(cd "$R/quellen/thema/programme" && grep -v '^#' HERKUNFT.txt | awk 'NF {print $2 "  " $1}' | sha256sum -c --quiet)
[ "$(find "$R/quellen/thema/programme" -name '*.svg' | wc -l)" = 5 ]

# neu: zweimal bauen
python3 -I "$R/werkzeug/thema-bauen.py" "$R/quellen" "$TMP/a" >"$TMP/bau.txt"
python3 -I "$R/werkzeug/thema-bauen.py" "$R/quellen" "$TMP/b" >/dev/null
diff -r "$TMP/a" "$TMP/b" >/dev/null || { echo "Bau nicht reproduzierbar" >&2; exit 1; }
[ -z "$(find "$TMP/a" -path '*48x48*' -print -quit)" ]

# alt: Thema-Vorlage 0.1 + Dokumente aus vorlage-0.6/neu (beide geprüft)
[ "$(sha256sum "$I/thema/SHA256SUMS" | cut -d' ' -f1)" = "$THEMA_SUMMEN_SHA" ]
(cd "$I/thema" && sha256sum -c --quiet SHA256SUMS)
[ "$(sha256sum "$I/vorlage-0.6/SHA256SUMS" | cut -d' ' -f1)" = "$V06_SUMMEN_SHA" ]
(cd "$I/vorlage-0.6" && sha256sum -c --quiet SHA256SUMS)
mkdir -p "$TMP/alt"
cp -r "$I/thema/vorlage/Querencia" "$TMP/alt/"
for rel in $(dateien_von apps/org.querencia.Dokumente); do
    q=$I/vorlage-0.6/neu/$rel
    [ ! -e "$TMP/alt/Querencia/$rel" ]
    cp "$q" "$TMP/alt/Querencia/$rel"
done
[ "$(find "$TMP/alt/Querencia" -type f | wc -l)" = 665 ]

# neu = alt + genau die erwarteten Dateien
erwartet=$(for n in $ERSETZT $NEU; do dateien_von "$n"; done | LC_ALL=C sort)
geaendert=$({ diff <(liste "$TMP/alt/Querencia") <(liste "$TMP/a/Querencia") || true; } | sed -n 's/^> [0-9a-f]*  //p' | LC_ALL=C sort)
entfernt=$(comm -23 <(cd "$TMP/alt/Querencia" && find . -type f | sed 's#^\./##' | LC_ALL=C sort) <(cd "$TMP/a/Querencia" && find . -type f | sed 's#^\./##' | LC_ALL=C sort))
[ -z "$entfernt" ] || { echo "neu entfernt Dateien: $entfernt" >&2; exit 1; }
[ "$geaendert" = "$erwartet" ] || { echo "Änderungen weichen ab:"; diff <(echo "$erwartet") <(echo "$geaendert"); exit 1; } >&2
for n in $ERSETZT; do for rel in $(dateien_von "$n"); do [ -e "$TMP/alt/Querencia/$rel" ]; done; done
for n in $NEU; do for rel in $(dateien_von "$n"); do [ ! -e "$TMP/alt/Querencia/$rel" ]; done; done
cmp "$TMP/alt/Querencia/index.theme" "$TMP/a/Querencia/index.theme"
for p in Archiv Software Dateisuche Rechner Kuerzel; do
    cmp "$R/quellen/thema/programme/org.querencia.$p.svg" "$TMP/a/Querencia/scalable/apps/org.querencia.$p.svg"
done

# Arbeitsordner schreiben
mkdir -p "$Z"
[ ! -e "$V" ] || chmod -R u+w "$V"
rm -rf -- "$V"
mkdir -p "$V/alt" "$V/neu"
cp -r "$TMP/alt/Querencia" "$V/alt/"
cp -r "$TMP/a/Querencia" "$V/neu/"
find "$V" -type d -exec chmod 0755 {} +
find "$V" -type f -exec chmod 0644 {} +
(cd "$V" && find alt neu -type f | LC_ALL=C sort | xargs sha256sum >SHA256SUMS)
chmod -R a-w "$V"
summe=$(sha256sum "$V/SHA256SUMS" | cut -d' ' -f1)
[ ! -e "$SKRIPT" ] || chmod u+w "$SKRIPT"
sed -e "s/@SUMMEN_SHA@/$summe/" -e "s/@KNOPF@/$KNOPF/" -e "s/@KNOPF_JOURNAL@/$KNOPF_JOURNAL/" \
    "$I/symbole-07/symbole-07-integrieren.sh.in" >"$SKRIPT"
! grep -q '@[A-Z_]*@' "$SKRIPT"
chmod 0555 "$SKRIPT"
{
    echo "# Symbole 0.7: Dateien, die aktivieren im Thema Querencia setzt (alles andere bleibt Stand 0.6)"
    echo "# ersetzt: $ERSETZT"
    echo "# neu:     $NEU"
    echo "$geaendert"
} >"$Z/AENDERUNG.txt"
echo "$(cat "$TMP/bau.txt")"
echo "SUMMEN_SHA=$summe; alt $(find "$V/alt" -type f | wc -l), neu $(find "$V/neu" -type f | wc -l) Dateien; gesetzt $(echo "$geaendert" | wc -l); Skript $(sha256sum "$SKRIPT" | cut -d' ' -f1)"
