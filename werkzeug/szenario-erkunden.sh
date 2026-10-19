#!/bin/bash
# G2-V: Erkundung – Panel starten, Anwendungen-Menü öffnen, Bilder machen.
set -u
. "$HMP04_PROFILE/env.sh"
. "$W/eingabe.sh"
"$QA" "$RES" 2>>"$OUT/erkunden.log"; sleep 1
~/opt/querencia/bin/querencia-panel >"$OUT/panel.log" 2>&1 &
sleep 4
grim "$OUT/e01-panel.png"
q "move 300 300" "wait 300" "move 40 12" "wait 300" "click" "wait 1500"
grim "$OUT/e02-anwendungen.png"
q "key Escape" "wait 300"
touch "$HMP04_PROFILE/logs/FERTIG"
