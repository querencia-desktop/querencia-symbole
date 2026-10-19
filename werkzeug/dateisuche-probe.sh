#!/bin/bash
# Probe für dateisuche-integrieren.sh (0.1.0 → 0.1.1) gegen umgelenkte Pfade (G2-V).
# Baut einen Wegwerfbaum als Kopie des Live-Ausgangs (nur lesend aus den Live-Pfaden)
# und spielt aktivieren / zurueck / Fehler / Signal durch. Ändert nichts Lebendes.
set -uo pipefail
SKRIPT=~/projects/querencia-dateisuche/integration/dateisuche-integrieren.sh
W=${1:?Arbeitsordner}
PASS=0; FAIL=0
ok()  { echo "PASS $*"; PASS=$((PASS+1)); }
nok() { echo "FAIL $*"; FAIL=$((FAIL+1)); }
[ -e "$W" ] && { chmod -R u+w "$W"; rm -rf "$W"; }
mkdir -p "$W"/{opt/bin,opt/dateisuche,apps,icons,state}
cp -a ~/opt/querencia/dateisuche/50ecd30fcef0ee3d ~/opt/querencia/dateisuche/b7ad2cd50f8ea388 ~/opt/querencia/dateisuche/b7ad2cd50f8ea388.herkunft "$W/opt/dateisuche/"   # wie live: beide Ablagen vorhanden
ln -s "$W/opt/dateisuche/50ecd30fcef0ee3d/querencia-dateisuche" "$W/opt/bin/querencia-dateisuche"
cp -p ~/.local/share/applications/org.querencia.Dateisuche.desktop "$W/apps/"
for f in ~/.local/share/icons/hicolor/*/apps/org.querencia.Dateisuche.*; do
  r=${f#~/.local/share/icons/}; mkdir -p "$W/icons/$(dirname "$r")"; cp -p "$f" "$W/icons/$r"; done
echo "Probe-Baum: $W"
export QDS_OPT=$W/opt QDS_APPS=$W/apps QDS_ICONS=$W/icons QDS_STATE=$W/state
stand() { (cd "$W" && find opt apps icons \( -type f -o -type l \) ! -name protokoll.txt ! -name '*.herkunft' -printf '%p %l\n' | sort; \
           cd "$W" && find apps icons -type f -exec sha256sum {} + | sort); }
lauf() { local erw=$1; shift; out=$("$@" 2>&1); rc=$?; echo "$out" | sed 's/^/    /'; [ "$rc" = "$erw" ] && ok "$* → Exit $rc" || nok "$* → Exit $rc (erwartet $erw)"; }
zust() { bash "$SKRIPT" pruefen 2>&1 | grep -E 'Programm|Menüeintrag|Symbole  ' | sed -E 's/.*: (alt|neu|fehlt|fremd).*/\1/' | tr '\n' ' ' | sed 's/ $//'; }

AUSGANG=$(stand)
lauf 0 bash "$SKRIPT" pruefen
[ "$(zust)" = "alt alt alt" ] && ok "Ausgang alt alt alt" || nok "Ausgang $(zust)"
# Fehler-/Signalfälle: jedes Mal Ausgang unverändert, Exit 1
for f in vor-erstem symbol-svg waehrend-programm nach-programm waehrend-menue signal-nach-programm signal-waehrend-menue; do
  QDS_PROBE=1 QDS_FEHLER=$f lauf 1 bash "$SKRIPT" aktivieren
  [ "$(stand)" = "$AUSGANG" ] && ok "nach Fehler $f: Baum gleich Ausgang" || nok "nach Fehler $f: Baum verändert"
done
lauf 0 bash "$SKRIPT" aktivieren
[ "$(zust)" = "neu neu neu" ] && ok "nach aktivieren neu neu neu" || nok "nach aktivieren $(zust)"
ls "$W"/icons/hicolor/*/apps/ | grep -c Dateisuche | xargs -I{} sh -c '[ {} = 1 ] && echo "PASS genau 1 Symboldatei (SVG)" || echo "FAIL {} Symboldateien"'
[ ! -e "$W/icons/hicolor/48x48" ] && ok "kein 48x48" || nok "48x48 vorhanden"
desktop-file-validate "$W/apps/org.querencia.Dateisuche.desktop" && ok "Starter gültig" || nok "Starter ungültig"
grep -q '^Exec=~/opt/querencia/dateisuche/b7ad2cd50f8ea388/querencia-dateisuche$' "$W/apps/org.querencia.Dateisuche.desktop" && ok "Exec zeigt auf 0.1.1-Ablage" || nok "Exec falsch"
lauf 0 bash "$SKRIPT" aktivieren      # zweites Mal: nichts zu tun
NEU=$(stand)
for f in zurueck-waehrend-menue zurueck-waehrend-programm symbol-16x16 symbol-svg; do
  QDS_PROBE=1 QDS_FEHLER=$f lauf 1 bash "$SKRIPT" zurueck
  [ "$(stand)" = "$NEU" ] && ok "nach Fehler $f (zurueck): Baum gleich 0.1.1" || nok "nach Fehler $f (zurueck): Baum verändert"
done
lauf 0 bash "$SKRIPT" zurueck
[ "$(stand)" = "$AUSGANG" ] && ok "zurueck: Baum byte-gleich mit Ausgang" || { nok "zurueck: Baum weicht ab"; diff <(echo "$AUSGANG") <(stand); }
lauf 0 bash "$SKRIPT" zurueck         # zweites Mal: nichts zu tun
# fremder Zustand → Exit 2, nichts geändert
echo fremd >> "$W/apps/org.querencia.Dateisuche.desktop"; F=$(stand)
lauf 2 bash "$SKRIPT" aktivieren
[ "$(stand)" = "$F" ] && ok "fremder Starter: nichts geändert" || nok "fremder Starter: verändert"
echo "--- Journal der Probe"; cat "$W/opt/protokoll.txt"
echo "ERGEBNIS: $PASS PASS, $FAIL FAIL"
