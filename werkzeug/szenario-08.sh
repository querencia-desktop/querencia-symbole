#!/bin/bash
# Symbole 0.8: Belegbilder für org.querencia.Dateien – Arbeitsfläche mit den
# Startern von Dateien und Files, Anwendungsmenü mit jeder Kategorie (Zeilen
# 0–9 nacheinander überfahren; Dateien steht unter Zubehör), Attrappe offen:
# Fensterleiste und Titelleiste; dazu symbol-nachschlagen.py: welche Datei
# GTK je Größe lädt. Beendet wird alles über die eigene Prozessgruppe
# (isoliert.py).
set -u
. "$HMP04_PROFILE/env.sh"
B=${RES%x*}; H=${RES#*x}
"$QA" "$RES" 2>>"$OUT/szenario.log"; sleep 1
gsettings set org.gnome.desktop.interface icon-theme Querencia
[ "$FARBE" = dunkel ] && gsettings set org.gnome.desktop.interface color-scheme prefer-dark
. "$W/eingabe.sh"
pt() { echo "move $(( $1 * 1280 / B )) $(( $2 * 720 / H ))"; }
panel_start() { "$PANEL" >>"$OUT/panel.log" 2>&1 & PAN=$!; sleep 4; }
panel_neu() { kill "$PAN"; wait "$PAN" 2>/dev/null; panel_start; }
python3 -I "$W/symbol-nachschlagen.py" 16,22,24,32,48,64,128 org.querencia.Dateien org.querencia.Files \
    >"$OUT/nachschlagen.txt" 2>&1
"$DESKTOP" >>"$OUT/desktop.log" 2>&1 &
sleep 3
panel_start
q "$(pt $((B/2)) $((H/2)))" "wait 300"
grim "$OUT/d00-arbeitsflaeche-$RES.png"
grim -g "0,0 360x260" "$OUT/d01-arbeitsflaeche-starter-$RES.png"
# Anwendungsmenü, jede Kategorie
q "$(pt 80 15)" "wait 300" "click" "wait 1500"; grim "$OUT/m00-anwendungen-$RES.png"
for k in 0 1 2 3 4 5 6 7 8 9; do
    y=$((46 + 24 * k))
    q "$(pt 80 "$y")" "wait 400" "$(pt 120 "$y")" "wait 1200"; grim "$OUT/m1$k-kategorie-$k-$RES.png"
done
panel_neu
q "$(pt $((B/2)) $((H/2)))" "wait 300"
# Attrappe: Fensterleiste und Titelleiste
python3 -I "$W/dateien-attrappe.py" 25 >"$OUT/attrappe.log" 2>&1 &
sleep 5
grim "$OUT/f00-fenster-$RES.png"
grim -g "0,$((H-32)) $((B/2))x32" "$OUT/f01-fensterleiste-$RES.png"
sleep 5
touch "$HMP04_PROFILE/logs/FERTIG"
