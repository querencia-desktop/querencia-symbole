#!/bin/bash
# Thema-2: Erkundung – Panel und Desktop starten, ein Bild, sonst nichts.
set -u
. "$HMP04_PROFILE/env.sh"
"$QA" "$RES" 2>>"$OUT/szenario.log"; sleep 1
[ "$ART" = thema ] && gsettings set org.gnome.desktop.interface icon-theme Querencia
gsettings get org.gnome.desktop.interface icon-theme >>"$OUT/szenario.log" 2>&1
~/opt/querencia/bin/querencia-desktop >>"$OUT/desktop.log" 2>&1 &
sleep 3
~/opt/querencia/bin/querencia-panel >>"$OUT/panel.log" 2>&1 &
sleep 5
grim "$OUT/e01-$RES.png"
touch "$HMP04_PROFILE/logs/FERTIG"
