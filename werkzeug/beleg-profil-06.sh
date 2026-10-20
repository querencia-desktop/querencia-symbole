#!/bin/bash
# Symbole 0.6: Wegwerfprofil für die Belegbilder (isolierter headless labwc),
# nach beleg-profil-thema2.sh. Kopiert lesend: rc.xml und environment aus
# querencia-runtime, panel.ini, dconf, alle Starter, hicolor und das Thema
# Querencia des Benutzers (Live-Stand 0.5.2 mit Dokumente 0.1.0); GTK-Theme
# Querencia-Klassisch als Link; gvfs im Wegwerf-Bus nicht aktivierbar.
#   beleg-profil-06.sh <profil> ausgang|neu
# „neu“: wendet symbole-integrieren-0.6.sh UMGELENKT (alle vier
# Umlenkungen) auf das Profil an. Mit BILDER_STARTER=<datei> ersetzt die
# Datei den Bilder-Starter im Profil (Sichtprüfung Bilder 0.2.2).
# GTK 4 liest ohne Settings-Portal (isoliert.py) gsettings nicht; das Thema
# steht deshalb in settings.ini des Profils.
set -euo pipefail
R=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
P=${1:?profil}; ART=${2:?ausgang|neu}
case $P in "$R"/gui-test/*) ;; *) echo "Profil nur unter $R/gui-test/" >&2; exit 2 ;; esac
[ ! -e "$P" ] || { echo "Profil $P gibt es schon (Probe löscht nichts)" >&2; exit 2; }
mkdir -p "$P"/{config/labwc,config/querencia,config/dconf,config/gtk-4.0,data/themes,opt/bin,state,logs}
L=~/projects/querencia-runtime/session/querencia/labwc
cp "$L/rc.xml" "$L/environment" "$P/config/labwc/"
cp ~/.config/querencia/panel.ini "$P/config/querencia/"
[ -f ~/.config/dconf/user ] && cp ~/.config/dconf/user "$P/config/dconf/"
ln -s ~/.local/share/themes/Querencia-Klassisch "$P/data/themes/Querencia-Klassisch"
cp -a ~/.local/share/applications "$P/data/applications"
mkdir -p "$P/data/icons"
cp -a ~/.local/share/icons/hicolor ~/.local/share/icons/Querencia "$P/data/icons/"
mkdir -p "$P/data/dbus-1/services"
for n in $(cd /usr/share/dbus-1/services && ls org.gtk.vfs.*.service | sed 's/\.service$//'); do
    printf '[D-BUS Service]\nName=%s\nExec=/bin/false\n' "$n" >"$P/data/dbus-1/services/$n.service"
done
if [ "$ART" = neu ]; then
    SYM_OPT=$P/opt SYM_APPS=$P/data/applications SYM_ICONS=$P/data/icons SYM_STATE=$P/state \
        bash "$R/integration/symbole-integrieren-0.6.sh" aktivieren
fi
if [ -n "${BILDER_STARTER:-}" ]; then
    cp -- "$BILDER_STARTER" "$P/data/applications/org.querencia.Bilder.desktop"
fi
schrift=$(gsettings get org.gnome.desktop.interface font-name | tr -d "'")
printf '[Settings]\ngtk-font-name=%s\ngtk-icon-theme-name=Querencia\n' "$schrift" >"$P/config/gtk-4.0/settings.ini"
echo "Profil $P ($ART) bereit"
