#!/bin/bash
# Symbole 0.7: Belegbilder – unteres Panel mit dem Knopf „Arbeitsfläche
# anzeigen“ (ohne und mit Fenstern, Knopf gedrückt), Menü Orte (Schreibtisch),
# Anwendungsmenü mit jeder Kategorie (Zeilen 0–9 nacheinander überfahren),
# dazu symbol-nachschlagen.py: welche Datei GTK je Name und Größe lädt.
# Beendet wird alles über die eigene Prozessgruppe (isoliert.py).
set -u
. "$HMP04_PROFILE/env.sh"
B=${RES%x*}; H=${RES#*x}
"$QA" "$RES" 2>>"$OUT/szenario.log"; sleep 1
gsettings set org.gnome.desktop.interface icon-theme Querencia
. "$W/eingabe.sh"
pt() { echo "move $(( $1 * 1280 / B )) $(( $2 * 720 / H ))"; }
panel_start() { "$PANEL" >>"$OUT/panel.log" 2>&1 & PAN=$!; sleep 4; }
panel_neu() { kill "$PAN"; wait "$PAN" 2>/dev/null; panel_start; }
python3 -I "$W/symbol-nachschlagen.py" 16,22,24,32,48 user-desktop user-desktop-symbolic \
    org.querencia.Archiv org.querencia.Software org.querencia.Dateisuche org.querencia.Rechner org.querencia.Kuerzel \
    >"$OUT/nachschlagen.txt" 2>&1
~/opt/querencia/bin/querencia-desktop >>"$OUT/desktop.log" 2>&1 &
sleep 3
panel_start
q "$(pt $((B/2)) $((H/2)))" "wait 300"
grim "$OUT/p00-ganz-$RES.png"
grim -g "0,$((H-32)) 320x32" "$OUT/p01-knopf-$RES.png"
# Fenster öffnen, dann den Knopf drücken (minimiert nur Fenster dieser Prüfsitzung)
A=$HMP04_PROFILE/data/applications
starte() { local exe; exe=$(sed -n 's/^Exec=\([^ ]*\).*/\1/p' "$A/$1" | head -1); "$exe" >"$OUT/$(basename "$exe").log" 2>&1 & sleep 4; }
starte org.querencia.Editor.desktop
starte org.querencia.Rechner.desktop
grim -g "0,$((H-32)) 320x32" "$OUT/p02-knopf-mit-fenstern-$RES.png"
q "$(pt 12 $((H-16)))" "wait 400" "click" "wait 1500"
grim "$OUT/p03-nach-klick-$RES.png"
grim -g "0,$((H-32)) 320x32" "$OUT/p04-knopf-gedrueckt-$RES.png"
q "$(pt $((B/2)) $((H/2)))" "wait 300"
# Menü Orte (zweiter Eintrag der oberen Leiste)
q "$(pt 175 15)" "wait 300" "click" "wait 1500"; grim "$OUT/o00-orte-$RES.png"
panel_neu
q "$(pt $((B/2)) $((H/2)))" "wait 300"
q "$(pt 80 15)" "wait 300" "click" "wait 1500"; grim "$OUT/m00-anwendungen-$RES.png"
for k in 0 1 2 3 4 5 6 7 8 9; do
    y=$((46 + 24 * k))
    q "$(pt 80 "$y")" "wait 400" "$(pt 120 "$y")" "wait 1200"; grim "$OUT/m1$k-kategorie-$k-$RES.png"
done
touch "$HMP04_PROFILE/logs/FERTIG"
