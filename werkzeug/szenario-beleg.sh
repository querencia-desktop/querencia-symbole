#!/bin/bash
# G2-V: Belegbilder – Panel-Menüs und Fensterliste mit den Programmsymbolen.
# Erst alle Menübilder (Klicks nur im Panel), DANACH die Programmfenster öffnen
# und nur noch fotografieren: keine Klicks und keine Tasten mehr, solange der
# Sitzungsdialog offen ist (seine Knöpfe sprächen logind auf dem echten
# Systembus an). Beendet wird alles über die eigene Prozessgruppe (isoliert.py).
set -u
. "$HMP04_PROFILE/env.sh"
B=${RES%x*}; H=${RES#*x}
# Diese qeingabe-Fassung (Kopie aus G2-T) bezieht absolute Zeigerkoordinaten
# fest auf 1280x720; pt() rechnet Bildschirmpunkte darauf um.
"$QA" "$RES" 2>>"$OUT/szenario.log"; sleep 1
. "$W/eingabe.sh"
pt() { echo "move $(( $1 * 1280 / B )) $(( $2 * 720 / H ))"; }
panel_start() { "$HOME/opt/querencia/bin/querencia-panel" >>"$OUT/panel.log" 2>&1 & PANEL=$!; sleep 4; }
panel_start
# Anwendungen öffnen (ein Klick), dann nur noch mit dem Zeiger wandern
q "$(pt 300 300)" "wait 300" "$(pt 40 12)" "wait 300" "click" "wait 1500"
q "$(pt 80 46)" "wait 400" "$(pt 120 46)" "wait 1500"; grim "$OUT/m01-anwendungen-zubehoer-$RES.png"
q "$(pt 120 70)" "wait 400" "$(pt 120 94)" "wait 400" "$(pt 150 94)" "wait 1500"; grim "$OUT/m02-anwendungen-systemwerkzeuge-$RES.png"
# System: Panel frisch starten (eigener Kindprozess im isolierten labwc), dann ein Klick
kill "$PANEL"; wait "$PANEL" 2>/dev/null; panel_start
q "$(pt 300 300)" "wait 300" "$(pt 269 12)" "wait 300" "click" "wait 1500"; grim "$OUT/m03-system-$RES.png"
q "$(pt 280 46)" "wait 400" "$(pt 320 46)" "wait 1500"; grim "$OUT/m04-system-einstellungen-$RES.png"
q "$(pt 320 70)" "wait 400" "$(pt 340 70)" "wait 1500"; grim "$OUT/m05-system-systemverwaltung-$RES.png"
kill "$PANEL"; wait "$PANEL" 2>/dev/null; panel_start
q "$(pt $((B/2)) $((H/2)))" "wait 300"
grim "$OUT/m06-menues-zu-$RES.png"
sleep 1
# Fenster öffnen (ab hier keine Eingaben mehr)
"$EDITOR_BIN" >"$OUT/editor.log" 2>&1 &
sleep 2
"$HOME/opt/querencia/bin/querencia-bilder" >"$OUT/bilder.log" 2>&1 &
sleep 2
"$HOME/opt/querencia/bin/querencia-einstellungen" >"$OUT/einstellungen.log" 2>&1 &
sleep 2
"$HOME/opt/querencia/bin/querencia-lautstaerke" >"$OUT/lautstaerke.log" 2>&1 &
sleep 2
"$HOME/opt/querencia/bin/querencia-dateisuche" >"$OUT/dateisuche.log" 2>&1 &
sleep 2
"$SYSMON_BIN" >"$OUT/systemmonitor.log" 2>&1 &
sleep 2
"$HOME/opt/querencia/bin/querencia-sitzung" --dialog >"$OUT/sitzung.log" 2>&1 &
sleep 4
grim "$OUT/f01-fensterliste-$RES.png"
grim -g "0,$((H-32)) ${B}x32" "$OUT/f02-fensterliste-leiste-$RES.png"
touch "$HMP04_PROFILE/logs/FERTIG"
