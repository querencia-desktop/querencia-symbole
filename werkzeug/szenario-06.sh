#!/bin/bash
# Symbole 0.6: Belegbilder – Anwendungsmenü mit jeder Kategorie (Zeilen 0–9
# nacheinander überfahren), danach Dokumente (mit PDF), Bilder und Editor
# öffnen, Fenster, Fensterliste und Titelleisten fotografieren (ab da keine
# Eingaben). Menüs schließt ein Neustart des Panels. Beendet wird alles über
# die eigene Prozessgruppe (isoliert.py).
set -u
. "$HMP04_PROFILE/env.sh"
B=${RES%x*}; H=${RES#*x}
"$QA" "$RES" 2>>"$OUT/szenario.log"; sleep 1
gsettings set org.gnome.desktop.interface icon-theme Querencia
. "$W/eingabe.sh"
# qeingabe bezieht absolute Zeigerkoordinaten fest auf 1280x720
pt() { echo "move $(( $1 * 1280 / B )) $(( $2 * 720 / H ))"; }
panel_start() { ~/opt/querencia/bin/querencia-panel >>"$OUT/panel.log" 2>&1 & PANEL=$!; sleep 4; }
panel_neu() { kill "$PANEL"; wait "$PANEL" 2>/dev/null; panel_start; }
~/opt/querencia/bin/querencia-desktop >>"$OUT/desktop.log" 2>&1 &
sleep 3
panel_start
q "$(pt $((B/2)) $((H/2)))" "wait 300"
q "$(pt 80 15)" "wait 300" "click" "wait 1500"; grim "$OUT/m00-anwendungen-$RES.png"
for k in 0 1 2 3 4 5 6 7 8 9; do
    y=$((46 + 24 * k))
    q "$(pt 80 "$y")" "wait 400" "$(pt 120 "$y")" "wait 1200"; grim "$OUT/m1$k-kategorie-$k-$RES.png"
done
panel_neu
q "$(pt $((B/2)) $((H/2)))" "wait 300"
A=$HMP04_PROFILE/data/applications
starte() { local exe; exe=$(sed -n 's/^Exec=\([^ ]*\).*/\1/p' "$A/$1" | head -1); shift; "$exe" "$@" >"$OUT/$(basename "$exe").log" 2>&1 & sleep 4; }
starte org.querencia.Editor.desktop
starte org.querencia.Bilder.desktop
starte org.querencia.Dokumente.desktop "$PDF"
sleep 3
grim "$OUT/f01-fenster-$RES.png"
grim -g "0,$((H-32)) ${B}x32" "$OUT/f02-fensterliste-$RES.png"
touch "$HMP04_PROFILE/logs/FERTIG"
