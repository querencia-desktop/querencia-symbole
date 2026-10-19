#!/bin/bash
# Thema-2: Belegbilder – Desktop, Anwendungsmenü (zwei Kategorien), Orte,
# System/Einstellungen, danach Files, Terminal, Screenshot, Editor und
# Systemmonitor öffnen und Fensterliste fotografieren (ab da keine Eingaben).
# Menüs schließt ein Neustart des Panels (eigener Kindprozess im isolierten
# labwc). Kein Sitzungsdialog (seine Knöpfe gingen an logind auf dem echten
# Systembus). Beendet wird alles über die eigene Prozessgruppe (isoliert.py).
set -u
. "$HMP04_PROFILE/env.sh"
B=${RES%x*}; H=${RES#*x}
"$QA" "$RES" 2>>"$OUT/szenario.log"; sleep 1
# Wie live über gsettings (Wegwerf-dconf); GTK liest es hier nur über
# settings.ini, siehe beleg-profil-thema2.sh.
[ "$ART" = thema ] && gsettings set org.gnome.desktop.interface icon-theme Querencia
echo "icon-theme im Wegwerf-dconf: $(gsettings get org.gnome.desktop.interface icon-theme)" >>"$OUT/szenario.log"
. "$W/eingabe.sh"
# qeingabe bezieht absolute Zeigerkoordinaten fest auf 1280x720
pt() { echo "move $(( $1 * 1280 / B )) $(( $2 * 720 / H ))"; }
panel_start() { ~/opt/querencia/bin/querencia-panel >>"$OUT/panel.log" 2>&1 & PANEL=$!; sleep 4; }
panel_neu() { kill "$PANEL"; wait "$PANEL" 2>/dev/null; panel_start; }
~/opt/querencia/bin/querencia-desktop >>"$OUT/desktop.log" 2>&1 &
sleep 3
panel_start
q "$(pt $((B/2)) $((H/2)))" "wait 300"
grim "$OUT/d01-desktop-$RES.png"
# Anwendungen
q "$(pt 80 15)" "wait 300" "click" "wait 1500"; grim "$OUT/m01-anwendungen-$RES.png"
q "$(pt 80 46)" "wait 400" "$(pt 120 46)" "wait 1500"; grim "$OUT/m02-anwendungen-zubehoer-$RES.png"
q "$(pt 120 70)" "wait 400" "$(pt 120 94)" "wait 400" "$(pt 150 94)" "wait 1500"; grim "$OUT/m03-anwendungen-systemwerkzeuge-$RES.png"
panel_neu
# Orte
q "$(pt 195 15)" "wait 300" "click" "wait 1500"; grim "$OUT/m04-orte-$RES.png"
panel_neu
# System
q "$(pt 269 15)" "wait 300" "click" "wait 1500"; grim "$OUT/m05-system-$RES.png"
q "$(pt 290 46)" "wait 400" "$(pt 330 46)" "wait 1500"; grim "$OUT/m06-system-einstellungen-$RES.png"
panel_neu
q "$(pt $((B/2)) $((H/2)))" "wait 300"
# Fenster öffnen (ab hier keine Eingaben mehr)
A=$HMP04_PROFILE/data/applications
starte() { local exe; exe=$(sed -n 's/^Exec=\([^ ]*\).*/\1/p' "$A/$1" | head -1); "$exe" >"$OUT/$2.log" 2>&1 & sleep 3; }
starte io.github.lgse.Strata.desktop files
starte org.example.Querencia.Terminal.desktop terminal
starte org.querencia.Editor.desktop editor
starte org.querencia.Systemmonitor.desktop systemmonitor
starte org.querencia.Screenshot.desktop screenshot
sleep 3
grim "$OUT/f01-fenster-$RES.png"
grim -g "0,$((H-32)) ${B}x32" "$OUT/f02-fensterliste-$RES.png"
touch "$HMP04_PROFILE/logs/FERTIG"
