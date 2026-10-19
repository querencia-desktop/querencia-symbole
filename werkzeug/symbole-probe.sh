#!/bin/bash
# Probe für integration/symbole-integrieren.sh gegen umgelenkte Pfade (G2-V).
# Wegwerfbaum = Kopie von ~/.local/share/icons/hicolor und
# ~/.local/share/applications (nur gelesen). Ändert nichts Lebendes.
set -uo pipefail
SKRIPT=~/projects/querencia-symbole/integration/symbole-integrieren.sh
W=${1:?Arbeitsordner}
PASS=0; FAIL=0
ok()  { echo "PASS $*"; PASS=$((PASS+1)); }
nok() { echo "FAIL $*"; FAIL=$((FAIL+1)); }
[ -e "$W" ] && { chmod -R u+w "$W"; rm -rf "$W"; }
mkdir -p "$W"/{opt/bin,icons,state}
cp -a ~/.local/share/icons/hicolor "$W/icons/"
cp -a ~/.local/share/applications "$W/apps"
echo "Probe-Baum: $W"
lauf() { local erw=$1; shift; out=$("$@" 2>&1); rc=$?; echo "$out" | sed 's/^/    /'; [ "$rc" = "$erw" ] && ok "${*: -1} → Exit $rc" || nok "${*: -1} → Exit $rc (erwartet $erw)"; }
stand() { (cd "$W" && find icons apps -type f -exec sha256sum {} + | LC_ALL=C sort; find icons apps -type d | LC_ALL=C sort); }
zust() { bash "$SKRIPT" pruefen 2>&1 | grep -v ': alt = Ausgang' | grep -oE ': (alt|neu|fremd)( |$)' | awk '{print $2}' | tr '\n' ' ' | sed 's/ $//'; }
ALT7="alt alt alt alt alt alt alt"; NEU7="neu neu neu neu neu neu neu"

echo "## Sperren (ohne Umlenkung, ohne Freigabe; nur teilweise umgelenkt)"
env -u SYM_OPT -u SYM_APPS -u SYM_ICONS -u SYM_STATE -u SYM_FREIGABE bash "$SKRIPT" aktivieren; rc=$?
[ $rc = 2 ] && ok "Live ohne SYM_FREIGABE → Exit 2" || nok "Live ohne SYM_FREIGABE → Exit $rc"
env -u SYM_APPS -u SYM_ICONS -u SYM_STATE SYM_OPT=$W/opt bash "$SKRIPT" aktivieren; rc=$?
[ $rc = 2 ] && ok "nur SYM_OPT umgelenkt → Exit 2" || nok "nur SYM_OPT umgelenkt → Exit $rc"

export SYM_OPT=$W/opt SYM_APPS=$W/apps SYM_ICONS=$W/icons SYM_STATE=$W/state
AUSGANG=$(stand)
echo "## Ausgang"
lauf 0 bash "$SKRIPT" pruefen
[ "$(zust)" = "$ALT7" ] && ok "Ausgang: $ALT7" || nok "Ausgang: $(zust)"

echo "## aktivieren mit Fehlern und Signalen"
for f in vor-erstem Systemmonitor-16x16 Einstellungen-scalable Lautstaerke-64x64 nach-symbolen Starter nach-touch signal-Bilder-128x128 signal-nach-symbolen signal-Starter; do
  SYM_PROBE=1 SYM_FEHLER=$f lauf 1 bash "$SKRIPT" aktivieren
  [ "$(stand)" = "$AUSGANG" ] && ok "nach Fehler $f: Baum byte-gleich Ausgang" || nok "nach Fehler $f: Baum verändert"
done

echo "## aktivieren"
M0=$(stat -c %Y "$W/icons/hicolor"); sleep 1.1
lauf 0 bash "$SKRIPT" aktivieren
[ "$(zust)" = "$NEU7" ] && ok "nach aktivieren: $NEU7" || nok "nach aktivieren: $(zust)"
[ "$(stat -c %Y "$W/icons/hicolor")" -gt "$M0" ] && ok "hicolor angestoßen (mtime neuer)" || nok "hicolor nicht angestoßen"
[ -z "$(find "$W/icons/hicolor" -path '*48x48*')" ] && ok "kein 48x48 im Baum" || nok "48x48 im Baum"
for a in Systemmonitor Einstellungen Editor Bilder Sitzung Lautstaerke; do
  n=$(ls "$W"/icons/hicolor/*/apps/org.querencia.$a.* | wc -l); [ "$n" = 8 ] && ok "$a: 8 Dateien" || nok "$a: $n Dateien"
done
grep -qx 'Icon=org.querencia.Einstellungen' "$W/apps/org.querencia.Einstellungen.desktop" && ok "Starter Icon=org.querencia.Einstellungen" || nok "Starter Icon="
desktop-file-validate "$W/apps/org.querencia.Einstellungen.desktop" && ok "Starter gültig" || nok "Starter ungültig"
D=$(diff <(echo "$AUSGANG") <(stand) | grep '^[<>]' | grep -vE 'org\.querencia\.(Systemmonitor|Einstellungen|Editor|Bilder|Sitzung|Lautstaerke)\.(png|svg|desktop)$')
[ -z "$D" ] && ok "sonst nichts verändert (andere Symbole, Starter, Ordner)" || { nok "Fremdes verändert"; echo "$D"; }
cmp -s "$W/icons/hicolor/scalable/apps/org.querencia.Lautstaerke.svg" ~/.local/share/icons/hicolor/scalable/apps/org.querencia.Lautstaerke.svg && ok "Lautstärke-SVG byte-gleich mit G2-J" || nok "Lautstärke-SVG geändert"
for a in Systemmonitor Editor Sitzung; do for b in Systemmonitor Editor Sitzung; do [ $a \< $b ] || continue
  cmp -s "$W/icons/hicolor/scalable/apps/org.querencia.$a.svg" "$W/icons/hicolor/scalable/apps/org.querencia.$b.svg" && nok "$a und $b byte-gleich" || ok "$a ≠ $b"; done; done
lauf 0 bash "$SKRIPT" aktivieren
NEU=$(stand)

echo "## zurueck mit Fehlern und Signalen"
for f in Starter Editor-scalable Lautstaerke-16x16 signal-Sitzung-22x22; do
  SYM_PROBE=1 SYM_FEHLER=$f lauf 1 bash "$SKRIPT" zurueck
  [ "$(stand)" = "$NEU" ] && ok "nach Fehler $f (zurueck): Baum byte-gleich G2-V" || nok "nach Fehler $f (zurueck): Baum verändert"
done
echo "## zurueck"
lauf 0 bash "$SKRIPT" zurueck
[ "$(stand)" = "$AUSGANG" ] && ok "zurueck: Baum byte-gleich Ausgang (Dateien und Ordner)" || { nok "zurueck: Baum weicht ab"; diff <(echo "$AUSGANG") <(stand); }
lauf 0 bash "$SKRIPT" zurueck

echo "## fremde Zustände"
cp "$W/icons/hicolor/64x64/apps/org.querencia.Bilder.png" "$W/icons/hicolor/48x48-test.png" 2>/dev/null
mkdir -p "$W/icons/hicolor/48x48/apps"; cp "$W/icons/hicolor/64x64/apps/org.querencia.Bilder.png" "$W/icons/hicolor/48x48/apps/org.querencia.Bilder.png"; rm -f "$W/icons/hicolor/48x48-test.png"
F=$(stand); lauf 2 bash "$SKRIPT" aktivieren
[ "$(stand)" = "$F" ] && ok "48x48 vorhanden: nichts geändert" || nok "48x48 vorhanden: verändert"
rm -rf "$W/icons/hicolor/48x48"
echo "# fremd" >>"$W/apps/org.querencia.Einstellungen.desktop"
F=$(stand); lauf 2 bash "$SKRIPT" aktivieren
[ "$(stand)" = "$F" ] && ok "fremder Starter: nichts geändert" || nok "fremder Starter: verändert"
echo "--- Journal der Probe"; cat "$W/opt/protokoll.txt"
echo "ERGEBNIS: $PASS PASS, $FAIL FAIL"
