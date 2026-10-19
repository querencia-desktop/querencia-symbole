#!/bin/bash
# G2-V: erzeugt integration/vorlage (neue Symbole, Starter Einstellungen mit eigenem
# Icon=) und integration/ausgang (Kopie des Live-Stands dieser Dateien, nur gelesen)
# sowie integration/SHA256SUMS. Danach SUMMEN_SHA in symbole-integrieren.sh eintragen.
set -euo pipefail
R=~/projects/querencia-symbole
I=$R/integration
APPS_LIVE=~/.local/share/applications
ICONS_LIVE=~/.local/share/icons
NAMEN="org.querencia.Systemmonitor org.querencia.Einstellungen org.querencia.Editor org.querencia.Bilder org.querencia.Sitzung org.querencia.Lautstaerke"
GROESSEN="16x16 22x22 24x24 32x32 64x64 128x128 256x256"
chmod -R u+w "$I/vorlage" "$I/ausgang" 2>/dev/null || true
rm -rf "$I/vorlage" "$I/ausgang"
mkdir -p "$I/vorlage/applications" "$I/ausgang/applications"
# shellcheck disable=SC2086
python3 -I "$R/werkzeug/rendern.py" "$R/quellen" "$I/vorlage" $NAMEN
# Lautstärke: SVG muss byte-gleich mit G2-J bleiben (lautstaerke-integrieren.sh prüft es)
cmp "$I/vorlage/icons/hicolor/scalable/apps/org.querencia.Lautstaerke.svg" \
    ~/projects/querencia-runtime-wt-lautstaerke/integration/vorschlag/org.querencia.Lautstaerke.svg
# Starter Einstellungen: Live-Datei, nur die Icon=-Zeile ersetzt
grep -qx 'Icon=preferences-system' "$APPS_LIVE/org.querencia.Einstellungen.desktop"
cp "$APPS_LIVE/org.querencia.Einstellungen.desktop" "$I/ausgang/applications/"
sed 's/^Icon=preferences-system$/Icon=org.querencia.Einstellungen/' "$APPS_LIVE/org.querencia.Einstellungen.desktop" >"$I/vorlage/applications/org.querencia.Einstellungen.desktop"
desktop-file-validate "$I/vorlage/applications/org.querencia.Einstellungen.desktop"
[ "$(diff "$I/ausgang/applications/org.querencia.Einstellungen.desktop" "$I/vorlage/applications/org.querencia.Einstellungen.desktop" | grep -c '^[<>]')" = 2 ]
# Ausgang der Symbole: was heute live liegt (fehlende Dateien fehlen auch hier)
for n in $NAMEN; do
    for g in $GROESSEN scalable; do
        [ "$g" = scalable ] && f=hicolor/$g/apps/$n.svg || f=hicolor/$g/apps/$n.png
        if [ -f "$ICONS_LIVE/$f" ]; then mkdir -p "$I/ausgang/icons/$(dirname "$f")"; cp -p "$ICONS_LIVE/$f" "$I/ausgang/icons/$f"; fi
    done
    [ ! -e "$ICONS_LIVE/hicolor/48x48/apps/$n.png" ]
done
[ ! -e "$I/vorlage/icons/hicolor/48x48" ]
(cd "$I" && find vorlage ausgang -type f | LC_ALL=C sort | xargs sha256sum >SHA256SUMS)
chmod -R a-w "$I/vorlage" "$I/ausgang"
echo "SUMMEN_SHA=$(sha256sum "$I/SHA256SUMS" | cut -d' ' -f1)"
echo "Vorlage: $(find "$I/vorlage" -type f | wc -l) Dateien, Ausgang: $(find "$I/ausgang" -type f | wc -l) Dateien"
