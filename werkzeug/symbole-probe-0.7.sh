#!/bin/bash
# Probe für symbole-07-integrieren.sh (Arbeitsordner) gegen umgelenkte Pfade,
# immer mit allen vier Umlenkungen SYM_OPT SYM_APPS SYM_ICONS SYM_STATE. Jeder
# Fall bekommt ein eigenes Probe-HOME im Live-Stand 0.6: Querencia =
# vorlage/alt (Thema-Vorlage 0.1 + Dokumente), hicolor = Vorlage 0.5.2 +
# Dokumente aus vorlage-0.6/neu, Starter aus dem Live-Stand (nur gelesen).
# Dort läuft auch symbole-integrieren-0.6.sh mit.
#   Sperre  live ohne SYM07_FREIGABE, halbe Umlenkungen → verweigert
#   A  aktivieren → Baum = vorlage/neu, hicolor und Starter unberührt →
#      0.6 sieht Thema=fremd, verweigert zurueck-0.5.2 → aktivieren noch
#      einmal (nichts) → zurueck-0.6 → Baum = vorlage/alt → 0.6 sieht
#      wieder „Hicolor=neu Thema=neu“ und kann zurueck-0.5.2
#   E  künstliche Fehler und Signale an jeder Stelle → Baum byte-gleich
#   F  fremde Stände, verfälschte Vorlage, belegte Sperren → verweigert
# Live wird nur gelesen. Die Probe löscht nichts (neue Unterordner,
# Beiseitelegen nach <arbeit>/weg/).
# Aufruf: bash symbole-probe-0.7.sh <neuer, leerer Arbeitsordner> [<integration-ordner>]
set -uo pipefail
I=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../integration" && pwd -P)
Z=${2:-~/projects/querencia-symbole-07/integration}
SKRIPT=$Z/symbole-07-integrieren.sh
S06=$I/symbole-integrieren-0.6.sh
W=${1:?Arbeitsordner}
[ ! -e "$W" ] || [ -z "$(ls -A "$W")" ] || { echo "Arbeitsordner $W ist nicht leer" >&2; exit 2; }
mkdir -p "$W/weg"
W=$(cd "$W" && pwd -P)
PASS=0; FAIL=0
ok()  { echo "PASS $*"; PASS=$((PASS+1)); }
nok() { echo "FAIL $*"; FAIL=$((FAIL+1)); }
DOK=org.querencia.Dokumente

baum() {
    local h=$W/$1/home g f
    mkdir -p "$h"/{opt/querencia/bin,.local/share/icons,.local/share/applications,.local/state/querencia} || exit 2
    cp -r "$I/vorlage/icons/hicolor" "$h/.local/share/icons/"
    for g in 16x16 22x22 24x24 32x32 64x64 128x128 256x256 scalable; do
        [ $g = scalable ] && f=$g/apps/$DOK.svg || f=$g/apps/$DOK.png
        mkdir -p "$h/.local/share/icons/hicolor/$g/apps"
        cp "$I/vorlage-0.6/neu/$f" "$h/.local/share/icons/hicolor/$f"
    done
    cp -r "$Z/vorlage/alt/Querencia" "$h/.local/share/icons/"
    find "$h/.local/share/icons" -type d -exec chmod 0755 {} +
    find "$h/.local/share/icons" -type f -exec chmod 0644 {} +
    tar -C ~/.local/share/applications -cf - --exclude=./mimeinfo.cache . | tar -C "$h/.local/share/applications" -xf -
    : >"$h/opt/querencia/protokoll.txt"
}
nutze() {
    H=$W/$1/home; B=$H/.local/share; Q=$B/icons/Querencia
    export SYM_OPT=$H/opt/querencia SYM_APPS=$B/applications SYM_ICONS=$B/icons SYM_STATE=$H/.local/state/querencia
}
beiseite() { mv -- "$1" "$W/weg/$(date +%s%N)-$(basename -- "$1")"; }
liste() { (cd "$1" && find . -type f -exec sha256sum {} + | sed 's#  \./#  #' | LC_ALL=C sort; find . -type d | LC_ALL=C sort); }
# Stand: Prüfsummen, Rechte und Ordner der Symbolbäume und Starter
stand() { (cd "$B" && find icons applications -type f -exec sha256sum {} + | LC_ALL=C sort; find icons -type d | LC_ALL=C sort; find icons applications \( -type f -o -type d \) -exec stat -c '%a %n' {} + | LC_ALL=C sort); }
nebenstand() { (cd "$B" && find icons/hicolor applications -type f -exec sha256sum {} + | LC_ALL=C sort); }
zust() { bash "$SKRIPT" pruefen 2>&1 | sed -n 's#^symbole-07: Thema [^:]*: \([a-z]*\) .*#\1#p'; }
z06() { bash "$S06" pruefen 2>&1 | sed -n 's#^symbole-integrieren: \(Hicolor\|Thema\) .*: \([a-z]*\)$#\1=\2#p' | tr '\n' ' ' | sed 's/ $//'; }
lauf() { local erw=$1; shift; out=$("$@" 2>&1); rc=$?; echo "$out" | sed 's/^/    /'; [ "$rc" = "$erw" ] && ok "[$FALL] ${*: -1} → Exit $rc" || nok "[$FALL] ${*: -1} → Exit $rc (erwartet $erw)"; }
kurz() { [ "$(printf '%s\n' "$1" | wc -l)" -le 1 ] && printf '%s' "$1" || printf '%s Zeilen, sha %s' "$(printf '%s\n' "$1" | wc -l)" "$(printf '%s' "$1" | sha256sum | cut -c1-12)"; }
pruef() { [ "$1" = "$2" ] && ok "[$FALL] $3: $(kurz "$1")" || nok "[$FALL] $3: $(kurz "$1") (erwartet $(kurz "$2"))"; }
fehler() { # befehl soll-stand stellen…
    local cmd=$1 soll=$2 f; shift 2
    for f in "$@"; do
        SYM_PROBE=1 SYM_FEHLER=$f lauf 1 bash "$SKRIPT" "$cmd"
        [ "$(stand)" = "$soll" ] && ok "[$FALL] Fehler $f bei $cmd: Baum byte-gleich" || { nok "[$FALL] Fehler $f bei $cmd: Baum verändert"; diff <(echo "$soll") <(stand) | head; }
        [ -z "$(find "$B/icons" -name '*.sym07-tmp' -print -quit)" ] && ok "[$FALL] Fehler $f: keine Hilfsdatei übrig" || nok "[$FALL] Fehler $f: Hilfsdatei übrig"
    done
}

echo "################ Sperren"
FALL=Sperre
livevor=$(liste ~/.local/share/icons/Querencia)
for cmd in aktivieren zurueck-0.6; do
    env -u SYM_OPT -u SYM_APPS -u SYM_ICONS -u SYM_STATE -u SYM07_FREIGABE bash "$SKRIPT" $cmd >/dev/null 2>&1; rc=$?
    [ $rc = 2 ] && ok "[Sperre] live $cmd ohne SYM07_FREIGABE → Exit 2" || nok "[Sperre] live $cmd ohne SYM07_FREIGABE → Exit $rc"
done
pruef "$(liste ~/.local/share/icons/Querencia)" "$livevor" "live Querencia unverändert"
baum halb; nutze halb
env -u SYM_STATE bash "$SKRIPT" aktivieren >/dev/null 2>&1; rc=$?
[ $rc = 2 ] && ok "[Sperre] nur drei Umlenkungen → Exit 2" || nok "[Sperre] nur drei Umlenkungen → Exit $rc"

echo "################ A: aktivieren, Abstimmung mit 0.6, zurueck-0.6"
FALL=A; baum a; nutze a
pruef "$(zust)" alt "0.7 pruefen am Anfang"
pruef "$(z06)" "Hicolor=neu Thema=neu" "0.6 pruefen am Anfang (Live-Stand 0.6)"
neben=$(nebenstand)
lauf 0 bash "$SKRIPT" aktivieren
pruef "$(zust)" neu "nach aktivieren"
pruef "$(liste "$Q")" "$(liste "$Z/vorlage/neu/Querencia")" "Querencia = vorlage/neu"
pruef "$(find "$Q" -type f | wc -l)" 713 "Dateien im Thema"
pruef "$(find "$Q" \( -type d ! -perm 0755 \) -o \( -type f ! -perm 0644 \) | wc -l)" 0 "Rechte 0755/0644"
pruef "$(find "$Q" -path '*48x48*' | wc -l)" 0 "kein 48x48"
pruef "$(nebenstand)" "$neben" "hicolor und Starter unberührt"
pruef "$(grep -c 'Symbole 0.7 aktiviert' "$SYM_OPT/protokoll.txt")" 1 "Journalzeile"
grep 'Symbole 0.7 aktiviert' "$SYM_OPT/protokoll.txt" | sed 's/^/    /'
pruef "$(ls -d "$SYM_STATE"/sicherung-symbole-07-aktivieren-* | wc -l)" 1 "Sicherung angelegt"
pruef "$(liste "$(ls -d "$SYM_STATE"/sicherung-symbole-07-aktivieren-*)/Querencia")" "$(liste "$Z/vorlage/alt/Querencia")" "Sicherung = Stand 0.6"
pruef "$(z06)" "Hicolor=neu Thema=fremd" "0.6 sieht 0.7 als fremd"
vor=$(stand); lauf 2 bash "$S06" zurueck-0.5.2
pruef "$(stand)" "$vor" "0.6 zurueck-0.5.2 verweigert, nichts geändert"
vor=$(stand); lauf 0 bash "$SKRIPT" aktivieren
pruef "$(stand)" "$vor" "aktivieren erneut: nichts geändert"
lauf 0 bash "$SKRIPT" zurueck-0.6
pruef "$(zust)" alt "nach zurueck-0.6"
pruef "$(liste "$Q")" "$(liste "$Z/vorlage/alt/Querencia")" "Querencia = vorlage/alt (Stand 0.6)"
pruef "$(find "$Q" \( -type d ! -perm 0755 \) -o \( -type f ! -perm 0644 \) | wc -l)" 0 "Rechte 0755/0644"
pruef "$(nebenstand)" "$neben" "hicolor und Starter unberührt"
pruef "$(z06)" "Hicolor=neu Thema=neu" "0.6 sieht wieder seinen Stand"
vor=$(stand); lauf 0 bash "$SKRIPT" zurueck-0.6
pruef "$(stand)" "$vor" "zurueck-0.6 erneut: nichts geändert"
lauf 0 bash "$S06" zurueck-0.5.2
pruef "$(z06)" "Hicolor=alt Thema=alt" "0.6 zurueck-0.5.2 danach möglich"
vor=$(stand); lauf 2 bash "$SKRIPT" aktivieren
pruef "$(stand)" "$vor" "0.7 auf Stand 0.5.2 verweigert (Thema fremd)"

echo "################ E: künstliche Fehler und Signale"
FALL=E-aktivieren; baum e1; nutze e1
soll=$(stand)
fehler aktivieren "$soll" vor-erstem datei-1 datei-29 datei-56 nach-angleichen nach-touch signal-datei-1 signal-datei-40 signal-nach-angleichen signal-nach-touch
pruef "$(zust)" alt "nach allen Fehlern"
pruef "$(grep -c 'abgebrochen' "$SYM_OPT/protokoll.txt")" 10 "Journal: 10 Abbrüche"
pruef "$(grep -c 'UNVOLLSTÄNDIG' "$SYM_OPT/protokoll.txt")" 0 "Journal: kein unvollständiges Rückrollen"
FALL=E-zurueck; baum e2; nutze e2
lauf 0 bash "$SKRIPT" aktivieren
soll=$(stand)
fehler zurueck-0.6 "$soll" vor-erstem datei-1 weg-scalable/apps/org.querencia.Archiv.svg weg-16x16/places/user-desktop-symbolic.png nach-angleichen nach-touch signal-datei-8 signal-weg-64x64/apps/org.querencia.Kuerzel.png signal-nach-touch
pruef "$(zust)" neu "nach allen Fehlern"

echo "################ F: fremde Stände, Vorlage, Sperren"
FALL=F-extra; baum f1; nutze f1
echo x >"$Q/16x16/apps/fremd.png"; chmod 0644 "$Q/16x16/apps/fremd.png"
vor=$(stand); lauf 2 bash "$SKRIPT" aktivieren; pruef "$(stand)" "$vor" "zusätzliche Datei: nichts geändert"
pruef "$(zust)" fremd "pruefen"
FALL=F-rechte; baum f2; nutze f2
chmod 0600 "$Q/index.theme"
vor=$(stand); lauf 2 bash "$SKRIPT" aktivieren; pruef "$(stand)" "$vor" "Rechte 0600: nichts geändert"
FALL=F-link; baum f3; nutze f3
beiseite "$Q/scalable/places/folder.svg"; ln -s ../../16x16/places/folder.png "$Q/scalable/places/folder.svg"
vor=$(stand); lauf 2 bash "$SKRIPT" aktivieren; pruef "$(stand)" "$vor" "Link im Thema: nichts geändert"
FALL=F-halb; baum f4; nutze f4
lauf 0 bash "$SKRIPT" aktivieren
beiseite "$Q/22x22/places/user-desktop.png"; cp "$Z/vorlage/alt/Querencia/22x22/places/user-desktop.png" "$Q/22x22/places/user-desktop.png"; chmod 0644 "$Q/22x22/places/user-desktop.png"
vor=$(stand); lauf 2 bash "$SKRIPT" zurueck-0.6; pruef "$(stand)" "$vor" "halb neu, halb alt: nichts geändert"
FALL=F-fehlt; baum f5; nutze f5
beiseite "$Q"
vor=$(stand); lauf 2 bash "$SKRIPT" aktivieren; pruef "$(stand)" "$vor" "kein Querencia: nichts geändert"
FALL=F-sperre; baum f6; nutze f6
for l in symbole-integrieren thema-integrieren; do
    exec 9>"$SYM_STATE/$l.lock"; flock -n 9
    vor=$(stand); lauf 2 bash "$SKRIPT" aktivieren; pruef "$(stand)" "$vor" "$l.lock belegt: nichts geändert"
    exec 9>&-
done
FALL=F-vorlage; baum f7; nutze f7
mkdir -p "$W/f7/integration"; cp -r "$Z/." "$W/f7/integration/"; chmod -R u+w "$W/f7/integration"
echo x >>"$W/f7/integration/vorlage/neu/Querencia/index.theme"
vor=$(stand); lauf 2 bash "$W/f7/integration/symbole-07-integrieren.sh" aktivieren; pruef "$(stand)" "$vor" "verfälschte Vorlage: nichts geändert"
cp "$Z/vorlage/neu/Querencia/index.theme" "$W/f7/integration/vorlage/neu/Querencia/index.theme"
echo x >"$W/f7/integration/vorlage/neu/Querencia/16x16/apps/untergeschoben.png"
vor=$(stand); lauf 2 bash "$W/f7/integration/symbole-07-integrieren.sh" aktivieren; pruef "$(stand)" "$vor" "Datei außerhalb SHA256SUMS: nichts geändert"

echo "################ Ergebnis: $PASS PASS, $FAIL FAIL"
[ "$FAIL" = 0 ]
