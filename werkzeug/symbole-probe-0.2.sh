#!/bin/bash
# Probe für symbole-integrieren.sh 0.2 gegen umgelenkte Pfade (G2-V), drei Ausgangslagen:
#   A  Ausgang 19.10. ~10:00 (aus integration/ausgang nachgebaut) → aktivieren → zurueck
#   B  heutiger Live-Stand (Kopie, nach der Aktivierung von 10:28) → aktivieren = nichts, zurueck
#   C  Live-Stand nach einer G2-X-Aktivierung (Starter: Exec/TryExec/Comment geändert,
#      Icon= bleibt) → zurueck ändert nur die Icon=-Zeile; zum Vergleich verweigert 0.1
# Jeweils mit Fehlerstellen und Signalen. Live wird nur gelesen.
set -uo pipefail
I=~/projects/querencia-symbole/integration
SKRIPT=$I/symbole-integrieren.sh
ALT01=$I/symbole-integrieren-0.1.sh
W=${1:?Arbeitsordner}
PASS=0; FAIL=0
ok()  { echo "PASS $*"; PASS=$((PASS+1)); }
nok() { echo "FAIL $*"; FAIL=$((FAIL+1)); }
ST=icons/../apps/org.querencia.Einstellungen.desktop
baum() { # Name → Kopie des Live-Stands (nur gelesen)
    local b=$W/$1; [ -e "$b" ] && { chmod -R u+w "$b"; rm -rf -- "${b:?}"; }
    mkdir -p "$b"/{opt/bin,icons,state}
    cp -a ~/.local/share/icons/hicolor "$b/icons/"
    cp -a ~/.local/share/applications "$b/apps"
}
nutze() { export SYM_OPT=$W/$1/opt SYM_APPS=$W/$1/apps SYM_ICONS=$W/$1/icons SYM_STATE=$W/$1/state; B=$W/$1; }
stand() { (cd "$B" && find icons apps -type f -exec sha256sum {} + | LC_ALL=C sort; find icons apps -type d | LC_ALL=C sort); }
zust() { bash "$1" pruefen 2>&1 | grep -v ': alt = Ausgang' | grep -oE ': (alt|neu|fremd)( |$)' | awk '{print $2}' | tr '\n' ' ' | sed 's/ $//'; }
lauf() { local erw=$1; shift; out=$("$@" 2>&1); rc=$?; echo "$out" | sed 's/^/    /'; [ "$rc" = "$erw" ] && ok "[$FALL] ${*: -1} → Exit $rc" || nok "[$FALL] ${*: -1} → Exit $rc (erwartet $erw)"; }
fehler() { # befehl soll-stand stellen…
    local cmd=$1 soll=$2 f; shift 2
    for f in "$@"; do
        SYM_PROBE=1 SYM_FEHLER=$f lauf 1 bash "$SKRIPT" "$cmd"
        [ "$(stand)" = "$soll" ] && ok "[$FALL] Fehler $f bei $cmd: Baum byte-gleich" || { nok "[$FALL] Fehler $f bei $cmd: Baum verändert"; diff <(echo "$soll") <(stand) | head; }
    done
}
ALL7() { printf "$1 %.0s" 1 2 3 4 5 6 7 | sed 's/ $//'; }
STARTER() { echo "$B/apps/org.querencia.Einstellungen.desktop"; }
nur_icon_diff() { # a b erwartetes-neues-Icon
    local d; d=$(diff "$1" "$2" | grep '^[<>]')
    [ "$(echo "$d" | wc -l)" = 2 ] && echo "$d" | grep -qx "> Icon=$3"
}

echo "################ Sperren"
FALL=Sperre
env -u SYM_OPT -u SYM_APPS -u SYM_ICONS -u SYM_STATE -u SYM_FREIGABE bash "$SKRIPT" zurueck; rc=$?
[ $rc = 2 ] && ok "[Sperre] live ohne SYM_FREIGABE → Exit 2" || nok "[Sperre] live ohne SYM_FREIGABE → Exit $rc"
env -u SYM_APPS -u SYM_ICONS -u SYM_STATE SYM_OPT=$W/x bash "$SKRIPT" zurueck; rc=$?
[ $rc = 2 ] && ok "[Sperre] nur SYM_OPT → Exit 2" || nok "[Sperre] nur SYM_OPT → Exit $rc"

echo "################ A: Ausgang → aktivieren → zurueck"
FALL=A; baum A; nutze A
for rel in $(cd "$I/vorlage" && find icons -type f); do
    if [ -e "$I/ausgang/$rel" ]; then cp -p "$I/ausgang/$rel" "$B/$rel"; else rm -f -- "$B/${rel:?}"; fi
done
cp -p "$I/ausgang/applications/org.querencia.Einstellungen.desktop" "$B/apps/"
AUSGANG=$(stand)
[ "$(zust "$SKRIPT")" = "$(ALL7 alt)" ] && ok "[A] Ausgang alt×7" || nok "[A] Ausgang $(zust "$SKRIPT")"
fehler aktivieren "$AUSGANG" vor-erstem Systemmonitor-16x16 Einstellungen-scalable Lautstaerke-64x64 nach-symbolen Starter nach-touch signal-Bilder-128x128 signal-Starter
lauf 0 bash "$SKRIPT" aktivieren
[ "$(zust "$SKRIPT")" = "$(ALL7 neu)" ] && ok "[A] nach aktivieren neu×7" || nok "[A] nach aktivieren $(zust "$SKRIPT")"
cmp -s "$(STARTER)" "$I/vorlage/applications/org.querencia.Einstellungen.desktop" && ok "[A] Starter = Referenz vorlage (nur Icon= anders als ausgang)" || nok "[A] Starter ≠ vorlage"
[ -z "$(find "$B/icons/hicolor" -path '*48x48*')" ] && ok "[A] kein 48x48" || nok "[A] 48x48"
NEU=$(stand)
lauf 0 bash "$SKRIPT" aktivieren
[ "$(stand)" = "$NEU" ] && ok "[A] zweites aktivieren: nichts geändert" || nok "[A] zweites aktivieren änderte"
fehler zurueck "$NEU" Starter signal-Starter Editor-scalable Lautstaerke-16x16 signal-Sitzung-22x22
lauf 0 bash "$SKRIPT" zurueck
[ "$(stand)" = "$AUSGANG" ] && ok "[A] zurueck: byte-gleich Ausgang (Dateien, Ordner)" || { nok "[A] zurueck weicht ab"; diff <(echo "$AUSGANG") <(stand); }
A_AUSGANG=$AUSGANG

echo "################ B: heutiger Live-Stand → aktivieren (nichts) → zurueck"
FALL=B; baum B; nutze B
LIVE=$(stand)
[ "$(zust "$SKRIPT")" = "$(ALL7 neu)" ] && ok "[B] Live-Stand neu×7" || nok "[B] Live-Stand $(zust "$SKRIPT")"
lauf 0 bash "$SKRIPT" aktivieren
[ "$(stand)" = "$LIVE" ] && ok "[B] aktivieren auf Live-Stand: nichts geändert" || nok "[B] aktivieren änderte"
fehler zurueck "$LIVE" Starter signal-Starter Systemmonitor-scalable Lautstaerke-128x128 signal-Bilder-24x24
lauf 0 bash "$SKRIPT" zurueck
[ "$(stand)" = "$A_AUSGANG" ] && ok "[B] zurueck: byte-gleich Ausgang 19.10." || { nok "[B] zurueck weicht ab"; diff <(echo "$A_AUSGANG") <(stand); }
nur_icon_diff ~/.local/share/applications/org.querencia.Einstellungen.desktop "$(STARTER)" preferences-system && ok "[B] Starter: nur die Icon=-Zeile geändert" || nok "[B] Starter: mehr als Icon= geändert"
desktop-file-validate "$(STARTER)" && ok "[B] Starter gültig" || nok "[B] Starter ungültig"
lauf 0 bash "$SKRIPT" aktivieren
[ "$(stand)" = "$LIVE" ] && ok "[B] erneut aktivieren: wieder byte-gleich Live-Stand" || nok "[B] erneut aktivieren weicht ab"

echo "################ C: nach G2-X (Starter Exec/TryExec/Comment geändert, Icon= bleibt)"
FALL=C; baum C; nutze C
sed -i -e 's#^Exec=.*#Exec=~/opt/querencia/einstellungen/0123456789abcdef/querencia-einstellungen#' \
       -e 's#^TryExec=.*#TryExec=~/opt/querencia/einstellungen/0123456789abcdef/querencia-einstellungen#' \
       -e 's#^Comment=.*#Comment=Probe G2-X: Arbeitsfläche, Hintergrund, Bildschirm#' "$(STARTER)"
desktop-file-validate "$(STARTER)" && ok "[C] simulierter G2-X-Starter gültig" || nok "[C] simulierter G2-X-Starter ungültig"
cp -p "$(STARTER)" "$W/c-starter-g2x.desktop"
G2X=$(stand)
echo "## zum Vergleich Fassung 0.1"
[ "$(zust "$ALT01")" = "$(ALL7 neu | sed 's/neu$/fremd/')" ] && ok "[C] 0.1 meldet Starter fremd" || nok "[C] 0.1: $(zust "$ALT01")"
FALL=C-0.1; lauf 2 bash "$ALT01" zurueck; FALL=C
[ "$(stand)" = "$G2X" ] && ok "[C] 0.1 zurueck verweigert, nichts geändert (der behobene Fehler)" || nok "[C] 0.1 änderte"
echo "## Fassung 0.2"
[ "$(zust "$SKRIPT")" = "$(ALL7 neu)" ] && ok "[C] 0.2 meldet neu×7" || nok "[C] 0.2: $(zust "$SKRIPT")"
lauf 0 bash "$SKRIPT" aktivieren
[ "$(stand)" = "$G2X" ] && ok "[C] aktivieren: nichts geändert" || nok "[C] aktivieren änderte"
fehler zurueck "$G2X" Starter signal-Starter Einstellungen-16x16 signal-Editor-64x64
lauf 0 bash "$SKRIPT" zurueck
nur_icon_diff "$W/c-starter-g2x.desktop" "$(STARTER)" preferences-system && ok "[C] zurueck: im G2-X-Starter nur Icon= → preferences-system" || nok "[C] Starter: mehr als Icon= geändert"
grep -q '^Exec=.*0123456789abcdef' "$(STARTER)" && grep -q '^Comment=Probe G2-X' "$(STARTER)" && ok "[C] Exec/TryExec/Comment von G2-X erhalten" || nok "[C] G2-X-Zeilen verloren"
desktop-file-validate "$(STARTER)" && ok "[C] Starter gültig" || nok "[C] Starter ungültig"
D=$(diff <(echo "$A_AUSGANG") <(stand) | grep '^[<>]' | grep -v 'org.querencia.Einstellungen.desktop$')
[ -z "$D" ] && ok "[C] Symbole byte-gleich Ausgang 19.10." || { nok "[C] Symbole weichen ab"; echo "$D"; }
lauf 0 bash "$SKRIPT" aktivieren
[ "$(stand)" = "$G2X" ] && ok "[C] erneut aktivieren: byte-gleich G2-X-Stand" || nok "[C] erneut aktivieren weicht ab"

echo "################ fremde Starter"
FALL=F; baum F; nutze F
sed -i 's/^Icon=.*/Icon=etwas-anderes/' "$(STARTER)"; S0=$(stand)
lauf 2 bash "$SKRIPT" zurueck; lauf 2 bash "$SKRIPT" aktivieren
[ "$(stand)" = "$S0" ] && ok "[F] anderer Icon-Wert: nichts geändert" || nok "[F] verändert"
sed -i 's/^Icon=.*/Icon=org.querencia.Einstellungen/' "$(STARTER)"; echo 'Icon=preferences-system' >>"$(STARTER)"; S0=$(stand)
lauf 2 bash "$SKRIPT" zurueck
[ "$(stand)" = "$S0" ] && ok "[F] zwei Icon=-Zeilen: nichts geändert" || nok "[F] verändert"
unset SYM_OPT SYM_APPS SYM_ICONS SYM_STATE
echo "ERGEBNIS: $PASS PASS, $FAIL FAIL"
