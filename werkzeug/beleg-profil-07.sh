#!/bin/bash
# Symbole 0.7: Wegwerfprofil für die Belegbilder (isolierter headless labwc),
# nach beleg-profil-06.sh. Kopiert lesend: rc.xml und environment aus
# querencia-runtime, panel.ini, dconf, alle Starter und hicolor des
# Benutzers; das Thema Querencia kommt aus vorlage/alt (Stand 0.6), nicht
# vom Live-Ordner (seit 21.10. 01:03 ist dort 0.7 aktiv); GTK-Theme
# Querencia-Klassisch als Link; gvfs im Wegwerf-Bus nicht aktivierbar.
#   beleg-profil-07.sh <profil> ausgang|neu [<integration-ordner>]
# „neu“: wendet symbole-07-integrieren.sh UMGELENKT (alle vier Umlenkungen)
# auf das Profil an. Das Thema steht in settings.ini des Profils (GTK 4
# liest ohne Settings-Portal gsettings nicht).
set -euo pipefail
R=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
P=${1:?profil}; ART=${2:?ausgang|neu}
Z=${3:-~/projects/querencia-symbole-07/integration}
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
cp -a ~/.local/share/icons/hicolor "$P/data/icons/"
cp -r "$Z/vorlage/alt/Querencia" "$P/data/icons/"
find "$P/data/icons/Querencia" -type d -exec chmod 0755 {} +
find "$P/data/icons/Querencia" -type f -exec chmod 0644 {} +
mkdir -p "$P/data/dbus-1/services"
for n in $(cd /usr/share/dbus-1/services && ls org.gtk.vfs.*.service | sed 's/\.service$//'); do
    printf '[D-BUS Service]\nName=%s\nExec=/bin/false\n' "$n" >"$P/data/dbus-1/services/$n.service"
done
: >"$P/opt/protokoll.txt"
SYM_OPT=$P/opt SYM_APPS=$P/data/applications SYM_ICONS=$P/data/icons SYM_STATE=$P/state \
    bash "$Z/symbole-07-integrieren.sh" pruefen
if [ "$ART" = neu ]; then
    SYM_OPT=$P/opt SYM_APPS=$P/data/applications SYM_ICONS=$P/data/icons SYM_STATE=$P/state \
        bash "$Z/symbole-07-integrieren.sh" aktivieren
fi
schrift=$(gsettings get org.gnome.desktop.interface font-name | tr -d "'")
printf '[Settings]\ngtk-font-name=%s\ngtk-icon-theme-name=Querencia\n' "$schrift" >"$P/config/gtk-4.0/settings.ini"
echo "Profil $P ($ART) bereit"
