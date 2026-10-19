#!/bin/bash
# Probe für symbole-integrieren.sh 0.3 gegen umgelenkte Pfade (Thema-2), immer
# mit allen vier Umlenkungen SYM_OPT SYM_APPS SYM_ICONS SYM_STATE:
#   Sperre  live ohne SYM_FREIGABE, halbe Umlenkungen → verweigert
#   A  Ausgang 19.10. ~10:00 (aus integration/ausgang nachgebaut) → aktivieren
#      → zurueck-0.3 → zurueck, jeweils mit Fehlerstellen und Signalen
#   B  heutiger Live-Stand (Kopie: G2-V aktiv, die vier 0.3-Namen fehlen)
#      → aktivieren (nur die 32 neuen Dateien) → zurueck-0.3 (byte-gleich
#      Live-Stand) → aktivieren → zurueck (Ausgang 19.10.)
#   F  fremde Stände (Symbol einer anderen Session, 48x48, fremder Starter)
#      → verweigert, nichts geändert
# Starter werden nie verändert außer der Icon=-Zeile von Einstellungen
# (G2-V-Komponente). Live wird nur gelesen.
# Aufruf: bash symbole-probe-0.3.sh <leerer Arbeitsordner>
set -uo pipefail
I=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../integration" && pwd -P)
SKRIPT=$I/symbole-integrieren.sh
W=${1:?Arbeitsordner}
mkdir -p "$W"
PASS=0; FAIL=0
ok()  { echo "PASS $*"; PASS=$((PASS+1)); }
nok() { echo "FAIL $*"; FAIL=$((FAIL+1)); }
NEU4="org.querencia.Files io.github.lgse.Strata org.querencia.Terminal org.querencia.Screenshot"
baum() { # Name → Kopie des Live-Stands (nur gelesen)
    local b=$W/$1; [ -e "$b" ] && { chmod -R u+w "$b"; rm -rf -- "${b:?}"; }
    mkdir -p "$b"/{opt/bin,icons,state}
    cp -a ~/.local/share/icons/hicolor "$b/icons/"
    cp -a ~/.local/share/applications "$b/apps"
}
nutze() { export SYM_OPT=$W/$1/opt SYM_APPS=$W/$1/apps SYM_ICONS=$W/$1/icons SYM_STATE=$W/$1/state; B=$W/$1; }
stand() { (cd "$B" && find icons apps -type f -exec sha256sum {} + | LC_ALL=C sort; find icons apps -type d | LC_ALL=C sort); }
starter() { (cd "$B/apps" && find . -type f -name '*.desktop' -exec sha256sum {} + | LC_ALL=C sort); }
zust() { bash "$SKRIPT" pruefen 2>&1 | grep -v ': alt = Ausgang' | grep -oE ': (alt|neu|fremd)( |$)' | awk '{print $2}' | tr '\n' ' ' | sed 's/ $//'; }
lauf() { local erw=$1; shift; out=$("$@" 2>&1); rc=$?; echo "$out" | sed 's/^/    /'; [ "$rc" = "$erw" ] && ok "[$FALL] ${*: -1} → Exit $rc" || nok "[$FALL] ${*: -1} → Exit $rc (erwartet $erw)"; }
fehler() { # befehl soll-stand stellen…
    local cmd=$1 soll=$2 f; shift 2
    for f in "$@"; do
        SYM_PROBE=1 SYM_FEHLER=$f lauf 1 bash "$SKRIPT" "$cmd"
        [ "$(stand)" = "$soll" ] && ok "[$FALL] Fehler $f bei $cmd: Baum byte-gleich" || { nok "[$FALL] Fehler $f bei $cmd: Baum verändert"; diff <(echo "$soll") <(stand) | head; }
    done
}
# Zustandszeile: 6× G2-V, 4× 0.3, Starter
Z() { echo "$1 $1 $1 $1 $1 $1 $2 $2 $2 $2 $3"; }
kein48() { [ -z "$(find "$B/icons/hicolor" -path '*48x48*' \( -name 'org.querencia.*' -o -name 'io.github.lgse.Strata.*' \))" ]; }

echo "################ Sperren"
FALL=Sperre
for cmd in aktivieren zurueck zurueck-0.3; do
    env -u SYM_OPT -u SYM_APPS -u SYM_ICONS -u SYM_STATE -u SYM_FREIGABE bash "$SKRIPT" $cmd >/dev/null 2>&1; rc=$?
    [ $rc = 2 ] && ok "[Sperre] live $cmd ohne SYM_FREIGABE → Exit 2" || nok "[Sperre] live $cmd ohne SYM_FREIGABE → Exit $rc"
done
for teil in "SYM_OPT" "SYM_OPT SYM_APPS" "SYM_OPT SYM_APPS SYM_ICONS" "SYM_ICONS SYM_STATE"; do
    args=(); for v in SYM_OPT SYM_APPS SYM_ICONS SYM_STATE; do args+=(-u "$v"); done
    setz=(); for v in $teil; do setz+=("$v=$W/halb/$v"); done
    env "${args[@]}" "${setz[@]}" SYM_FREIGABE=ja bash "$SKRIPT" aktivieren >/dev/null 2>&1; rc=$?
    [ $rc = 2 ] && ok "[Sperre] nur $teil umgelenkt → Exit 2" || nok "[Sperre] nur $teil umgelenkt → Exit $rc"
done
[ ! -e "$W/halb" ] && ok "[Sperre] halbe Umlenkung legte nichts an" || nok "[Sperre] halbe Umlenkung legte $W/halb an"

echo "################ A: Ausgang 19.10. → aktivieren → zurueck-0.3 → zurueck"
FALL=A; baum A; nutze A
for rel in $(cd "$I/vorlage" && find icons -type f); do
    if [ -e "$I/ausgang/$rel" ]; then cp -p "$I/ausgang/$rel" "$B/$rel"; else rm -f -- "$B/${rel:?}"; fi
done
cp -p "$I/ausgang/applications/org.querencia.Einstellungen.desktop" "$B/apps/"
AUSGANG=$(stand); ST0=$(starter)
[ "$(zust)" = "$(Z alt alt alt)" ] && ok "[A] Ausgang alt×11" || nok "[A] Ausgang $(zust)"
fehler aktivieren "$AUSGANG" vor-erstem Systemmonitor-16x16 Lautstaerke-64x64 Files-16x16 Strata-scalable Screenshot-256x256 nach-symbolen Starter nach-touch signal-Terminal-64x64 signal-Starter
lauf 0 bash "$SKRIPT" aktivieren
[ "$(zust)" = "$(Z neu neu neu)" ] && ok "[A] nach aktivieren neu×11" || nok "[A] nach aktivieren $(zust)"
kein48 && ok "[A] kein 48x48" || nok "[A] 48x48"
for n in $NEU4; do
    cmp -s "$B/icons/hicolor/scalable/apps/$n.svg" "$I/vorlage/icons/hicolor/scalable/apps/$n.svg" && ok "[A] $n.svg = Vorlage" || nok "[A] $n.svg fehlt/abweichend"
done
cmp -s "$B/icons/hicolor/32x32/apps/io.github.lgse.Strata.png" "$B/icons/hicolor/32x32/apps/org.querencia.Files.png" && ok "[A] Strata-Kopie = Files" || nok "[A] Strata ≠ Files"
NEU=$(stand)
lauf 0 bash "$SKRIPT" aktivieren
[ "$(stand)" = "$NEU" ] && ok "[A] zweites aktivieren: nichts geändert" || nok "[A] zweites aktivieren änderte"
fehler zurueck-0.3 "$NEU" Files-16x16 Strata-128x128 signal-Terminal-scalable Screenshot-22x22 nach-touch
lauf 0 bash "$SKRIPT" zurueck-0.3
[ "$(zust)" = "$(Z neu alt neu)" ] && ok "[A] zurueck-0.3: G2-V neu, 0.3 alt, Starter neu" || nok "[A] zurueck-0.3: $(zust)"
rest=0; for n in $NEU4; do [ -z "$(find "$B/icons" -name "$n.*" -print -quit)" ] || rest=1; done
[ $rest = 0 ] && ok "[A] zurueck-0.3: keine Datei der vier Namen mehr" || nok "[A] nach zurueck-0.3 noch Dateien der vier Namen"
lauf 0 bash "$SKRIPT" zurueck-0.3
fehler zurueck "$(stand)" Starter signal-Starter Editor-scalable Lautstaerke-16x16 signal-Sitzung-22x22
lauf 0 bash "$SKRIPT" zurueck
[ "$(stand)" = "$AUSGANG" ] && ok "[A] zurueck: byte-gleich Ausgang (Dateien, Ordner)" || { nok "[A] zurueck weicht ab"; diff <(echo "$AUSGANG") <(stand); }
lauf 0 bash "$SKRIPT" aktivieren
fehler zurueck "$(stand)" Files-scalable signal-Strata-16x16 Starter
lauf 0 bash "$SKRIPT" zurueck
[ "$(stand)" = "$AUSGANG" ] && ok "[A] zurueck aus voll aktiv: byte-gleich Ausgang" || { nok "[A] zurueck aus voll aktiv weicht ab"; diff <(echo "$AUSGANG") <(stand); }
A_AUSGANG=$AUSGANG

echo "################ B: heutiger Live-Stand → aktivieren → zurueck-0.3 → aktivieren → zurueck"
FALL=B; baum B; nutze B
LIVE=$(stand); ST0=$(starter)
[ "$(zust)" = "$(Z neu alt neu)" ] && ok "[B] Live-Stand: G2-V neu, 0.3 alt, Starter neu" || nok "[B] Live-Stand $(zust)"
fehler aktivieren "$LIVE" vor-erstem Files-16x16 Strata-24x24 signal-Screenshot-scalable Terminal-256x256 nach-touch
lauf 0 bash "$SKRIPT" aktivieren
[ "$(zust)" = "$(Z neu neu neu)" ] && ok "[B] nach aktivieren neu×11" || nok "[B] nach aktivieren $(zust)"
D=$(diff <(echo "$LIVE") <(stand) | grep '^[<>]')
[ -z "$(echo "$D" | grep '^<')" ] && ok "[B] aktivieren: nichts entfernt oder überschrieben" || { nok "[B] aktivieren änderte Bestehendes"; echo "$D" | grep '^<' | head; }
[ "$(echo "$D" | grep -c '^>')" = 32 ] && ok "[B] aktivieren: genau 32 neue Dateien" || nok "[B] aktivieren: $(echo "$D" | grep -c '^>') neue Einträge"
echo "$D" | grep '^>' | grep -vqE '/(org\.querencia\.(Files|Terminal|Screenshot)|io\.github\.lgse\.Strata)\.(png|svg)$' && nok "[B] fremde Datei neu" || ok "[B] neu sind nur die vier Namen"
[ "$(starter)" = "$ST0" ] && ok "[B] kein Starter verändert" || nok "[B] Starter verändert"
kein48 && ok "[B] kein 48x48" || nok "[B] 48x48"
NEU=$(stand)
lauf 0 bash "$SKRIPT" zurueck-0.3
[ "$(stand)" = "$LIVE" ] && ok "[B] zurueck-0.3: byte-gleich Live-Stand" || { nok "[B] zurueck-0.3 weicht ab"; diff <(echo "$LIVE") <(stand) | head; }
lauf 0 bash "$SKRIPT" aktivieren
[ "$(stand)" = "$NEU" ] && ok "[B] erneut aktivieren: byte-gleich wie zuvor" || nok "[B] erneut aktivieren weicht ab"
lauf 0 bash "$SKRIPT" zurueck
# Live-Starter anderer Programme können sich zwischen den Kopien A und B ändern
# (parallele Sessions); verglichen werden darum die Symbole mit A, die Starter mit B.
D=$(diff <(echo "$A_AUSGANG" | grep '  icons/') <(stand | grep '  icons/') | grep '^[<>]')
[ -z "$D" ] && ok "[B] zurueck: Symbole byte-gleich Ausgang 19.10." || { nok "[B] zurueck: Symbole weichen ab"; echo "$D" | head; }
[ "$(starter | grep -v 'org.querencia.Einstellungen.desktop$')" = "$(echo "$ST0" | grep -v 'org.querencia.Einstellungen.desktop$')" ] && ok "[B] zurueck: alle anderen Starter unverändert" || nok "[B] zurueck: andere Starter verändert"
d=$(diff ~/.local/share/applications/org.querencia.Einstellungen.desktop "$B/apps/org.querencia.Einstellungen.desktop" | grep '^[<>]')
[ "$(echo "$d" | wc -l)" = 2 ] && echo "$d" | grep -qx '> Icon=preferences-system' && ok "[B] zurueck: im heutigen Einstellungen-Starter nur Icon= → preferences-system (Exec usw. von G2-X bleiben)" || nok "[B] Starter: mehr als Icon= geändert"
desktop-file-validate "$B/apps/org.querencia.Einstellungen.desktop" && ok "[B] Einstellungen-Starter gültig" || nok "[B] Einstellungen-Starter ungültig"
lauf 0 bash "$SKRIPT" aktivieren
lauf 0 bash "$SKRIPT" zurueck-0.3
[ "$(stand)" = "$LIVE" ] && ok "[B] aktivieren + zurueck-0.3 aus Ausgang: byte-gleich Live-Stand" || nok "[B] weicht vom Live-Stand ab"
grep -c . "$B/opt/protokoll.txt" | grep -q . && ok "[B] Journal geschrieben ($(grep -c . "$B/opt/protokoll.txt") Zeilen)" || nok "[B] kein Journal"

echo "################ F: fremde Stände"
FALL=F; baum F; nutze F
printf '<svg xmlns="http://www.w3.org/2000/svg"/>\n' >"$B/icons/hicolor/scalable/apps/org.querencia.Terminal.svg"; S0=$(stand)
[ "$(zust)" = "neu neu neu neu neu neu alt alt fremd alt neu" ] && ok "[F] Terminal-Symbol einer anderen Session: fremd" || nok "[F] $(zust)"
lauf 2 bash "$SKRIPT" aktivieren; lauf 2 bash "$SKRIPT" zurueck-0.3; lauf 2 bash "$SKRIPT" zurueck
[ "$(stand)" = "$S0" ] && ok "[F] fremdes Terminal-Symbol: nichts geändert" || nok "[F] verändert"
rm -f "$B/icons/hicolor/scalable/apps/org.querencia.Terminal.svg"
mkdir -p "$B/icons/hicolor/48x48/apps"; cp "$I/vorlage/icons/hicolor/64x64/apps/org.querencia.Files.png" "$B/icons/hicolor/48x48/apps/org.querencia.Files.png"; S0=$(stand)
lauf 2 bash "$SKRIPT" aktivieren
[ "$(stand)" = "$S0" ] && ok "[F] Files 48x48 vorhanden: verweigert, nichts geändert" || nok "[F] verändert"
rm -f "$B/icons/hicolor/48x48/apps/org.querencia.Files.png"
sed -i 's/^Icon=.*/Icon=etwas-anderes/' "$B/apps/org.querencia.Einstellungen.desktop"; S0=$(stand)
lauf 2 bash "$SKRIPT" aktivieren; lauf 2 bash "$SKRIPT" zurueck-0.3
[ "$(stand)" = "$S0" ] && ok "[F] fremder Einstellungen-Starter: nichts geändert" || nok "[F] verändert"
unset SYM_OPT SYM_APPS SYM_ICONS SYM_STATE
echo "ERGEBNIS: $PASS PASS, $FAIL FAIL"
[ "$FAIL" = 0 ]
