#!/bin/bash
# Probe für integration/programm-integrieren.sh (editor, systemmonitor) gegen
# umgelenkte Pfade (G2-V). Wegwerfbaum aus Kopien (nur gelesen). Die neue
# Ablage bleibt nach Rückrollen/zurueck absichtlich liegen (wie G2-T/G2-M);
# Vergleiche schließen sie deshalb aus und prüfen sie getrennt.
set -uo pipefail
SKRIPT=~/projects/querencia-symbole/integration/programm-integrieren.sh
W=${1:?Arbeitsordner}
PASS=0; FAIL=0
ok()  { echo "PASS $*"; PASS=$((PASS+1)); }
nok() { echo "FAIL $*"; FAIL=$((FAIL+1)); }
lauf() { local erw=$1; shift; out=$("$@" 2>&1); rc=$?; echo "$out" | sed 's/^/    /'; [ "$rc" = "$erw" ] && ok "$K ${*: -1} → Exit $rc" || nok "$K ${*: -1} → Exit $rc (erwartet $erw)"; }
for K in editor systemmonitor; do
  echo "################ $K"
  B=$W/$K; [ -e "$B" ] && { chmod -R u+w "$B"; rm -rf "$B"; }
  mkdir -p "$B"/{opt/bin,opt/$K,apps,state}
  ziel=$(readlink ~/opt/querencia/bin/querencia-$K); alt16=$(basename "$(dirname "$ziel")")
  cp -a "~/opt/querencia/$K/$alt16" "$B/opt/$K/"
  ln -s "$B/opt/$K/$alt16/querencia-$K" "$B/opt/bin/querencia-$K"
  cp -p ~/.local/share/applications/org.querencia.*.desktop "$B/apps/"
  neu16=$(sed -n "/^$K)/,/;;/s/^ *PROG_NEU=\(.\{16\}\).*/\1/p" "$SKRIPT")
  stand() { (cd "$B" && find opt apps \( -type f -o -type l \) ! -name protokoll.txt -printf '%p %l\n' | grep -v "/$neu16" | LC_ALL=C sort; find apps -type f -exec sha256sum {} + | LC_ALL=C sort); }
  zust() { bash "$SKRIPT" $K pruefen 2>&1 | grep -E 'Programm |Starter ' | sed -E 's/.*: (alt|neu|fehlt|fremd).*/\1/' | tr '\n' ' ' | sed 's/ $//'; }
  ALT=$([ $K = editor ] && echo "alt alt" || echo alt); NEU=$([ $K = editor ] && echo "neu neu" || echo neu)
  env -u SYM_OPT -u SYM_APPS -u SYM_STATE -u SYM_FREIGABE bash "$SKRIPT" $K aktivieren; rc=$?
  [ $rc = 2 ] && ok "$K Live ohne SYM_FREIGABE → Exit 2" || nok "$K Live ohne SYM_FREIGABE → Exit $rc"
  env -u SYM_APPS -u SYM_STATE SYM_OPT=$B/opt bash "$SKRIPT" $K aktivieren; rc=$?
  [ $rc = 2 ] && ok "$K nur SYM_OPT umgelenkt → Exit 2" || nok "$K nur SYM_OPT umgelenkt → Exit $rc"
  export SYM_OPT=$B/opt SYM_APPS=$B/apps SYM_STATE=$B/state
  AUSGANG=$(stand)
  lauf 0 bash "$SKRIPT" $K pruefen
  [ "$(zust)" = "$ALT" ] && ok "$K Ausgang $ALT" || nok "$K Ausgang $(zust)"
  FEHLER="vor-erstem nach-ablage programm signal-programm nach-programm"; [ $K = editor ] && FEHLER="$FEHLER starter signal-starter"
  for f in $FEHLER; do
    SYM_PROBE=1 SYM_FEHLER=$f lauf 1 bash "$SKRIPT" $K aktivieren
    [ "$(stand)" = "$AUSGANG" ] && ok "$K nach Fehler $f: Baum gleich Ausgang" || { nok "$K nach Fehler $f: Baum verändert"; diff <(echo "$AUSGANG") <(stand); }
  done
  lauf 0 bash "$SKRIPT" $K aktivieren
  [ "$(zust)" = "$NEU" ] && ok "$K nach aktivieren $NEU" || nok "$K nach aktivieren $(zust)"
  a=$B/opt/$K/$neu16
  [ "$(stat -c %a "$a")" = 555 ] && [ "$(stat -c %a "$a/querencia-$K")" = 555 ] && ok "$K Ablage 0555" || nok "$K Ablage-Rechte"
  [ -f "$a.herkunft" ] && ok "$K .herkunft vorhanden" || nok "$K .herkunft fehlt"
  if [ $K = editor ]; then
    desktop-file-validate "$B/apps/org.querencia.Editor.desktop" && ok "editor Starter gültig" || nok "editor Starter ungültig"
    grep -q "^Exec=~/opt/querencia/editor/$neu16/querencia-editor %U$" "$B/apps/org.querencia.Editor.desktop" && ok "editor Exec auf neue Ablage" || nok "editor Exec"
  fi
  D=$(diff <(echo "$AUSGANG") <(stand) | grep '^[<>]' | grep -vE "bin/querencia-$K |org\.querencia\.Editor\.desktop$")
  [ -z "$D" ] && ok "$K sonst nichts verändert" || { nok "$K Fremdes verändert"; echo "$D"; }
  lauf 0 bash "$SKRIPT" $K aktivieren
  NEUSTAND=$(stand)
  FEHLER="zurueck-programm"; [ $K = editor ] && FEHLER="zurueck-starter signal-zurueck-starter zurueck-programm"
  for f in $FEHLER; do
    SYM_PROBE=1 SYM_FEHLER=$f lauf 1 bash "$SKRIPT" $K zurueck
    [ "$(stand)" = "$NEUSTAND" ] && ok "$K nach Fehler $f (zurueck): Baum gleich neu" || nok "$K nach Fehler $f (zurueck): verändert"
  done
  lauf 0 bash "$SKRIPT" $K zurueck
  [ "$(stand)" = "$AUSGANG" ] && ok "$K zurueck: Baum gleich Ausgang (neue Ablage bleibt)" || { nok "$K zurueck weicht ab"; diff <(echo "$AUSGANG") <(stand); }
  [ "$(sha256sum "$a/querencia-$K" | cut -c1-16)" = "$neu16" ] && ok "$K neue Ablage unversehrt" || nok "$K neue Ablage verändert"
  lauf 0 bash "$SKRIPT" $K zurueck
  ln -sfn /bin/true "$B/opt/bin/querencia-$K"; F=$(stand)
  lauf 2 bash "$SKRIPT" $K aktivieren
  [ "$(stand)" = "$F" ] && ok "$K fremder Link: nichts geändert" || nok "$K fremder Link: verändert"
  echo "--- Journal $K"; cat "$B/opt/protokoll.txt"
  unset SYM_OPT SYM_APPS SYM_STATE
done
echo "ERGEBNIS: $PASS PASS, $FAIL FAIL"
