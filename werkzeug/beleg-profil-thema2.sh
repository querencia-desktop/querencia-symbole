#!/bin/bash
# Thema-2: Wegwerfprofil für die Belegbilder (isolierter headless labwc), nach
# beleg-profil.sh (G2-V). Kopiert lesend: rc.xml, environment, panel.ini, dconf,
# Starter und hicolor des Benutzers; GTK-Theme Querencia-Klassisch als Link;
# gvfs im Wegwerf-Bus nicht aktivierbar (wsdd-Falle, 13 §5).
#   beleg-profil-thema2.sh <profil> ausgang|thema
# „thema“: wendet symbole-integrieren.sh (ab 0.4 mit den Icon=-Zeilen von
# Terminal und Screenshot) und thema-integrieren.sh UMGELENKT (alle
# Umlenkungen) auf das Profil an und setzt in der PROFIL-Kopie des
# Files-Starters die Icon=-Zeile, die QF-0o-2 setzen soll (Simulation). Das
# Symbolthema stellt szenario-thema2.sh per gsettings im Wegwerf-dconf ein.
set -euo pipefail
R=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
P=${1:?profil}; ART=${2:?ausgang|thema}
case $P in "$R"/gui-test/*) ;; *) echo "Profil nur unter $R/gui-test/" >&2; exit 2 ;; esac
[ -e "$P" ] && { chmod -R u+rwX "$P"; rm -rf "$P"; }
mkdir -p "$P"/{config/labwc,config/querencia,config/dconf,data/themes,opt/bin,state,logs}
L=~/projects/querencia-runtime/session/querencia/labwc
cp "$L/rc.xml" "$L/environment" "$P/config/labwc/"
cp ~/.config/querencia/panel.ini "$P/config/querencia/"
[ -f ~/.config/dconf/user ] && cp ~/.config/dconf/user "$P/config/dconf/"
ln -s ~/.local/share/themes/Querencia-Klassisch "$P/data/themes/Querencia-Klassisch"
cp -a ~/.local/share/applications "$P/data/applications"
mkdir -p "$P/data/icons"; cp -a ~/.local/share/icons/hicolor "$P/data/icons/"
mkdir -p "$P/data/dbus-1/services"
for n in $(cd /usr/share/dbus-1/services && ls org.gtk.vfs.*.service | sed 's/\.service$//'); do
    printf '[D-BUS Service]\nName=%s\nExec=/bin/false\n' "$n" >"$P/data/dbus-1/services/$n.service"
done
if [ "$ART" = thema ]; then
    SYM_OPT=$P/opt SYM_APPS=$P/data/applications SYM_ICONS=$P/data/icons SYM_STATE=$P/state \
        bash "$R/integration/symbole-integrieren.sh" aktivieren
    THM_OPT=$P/opt THM_ICONS=$P/data/icons THM_STATE=$P/state \
        bash "$R/integration/thema-integrieren.sh" aktivieren
    A=$P/data/applications
    sed -i 's/^Icon=.*/Icon=org.querencia.Files/' "$A/io.github.lgse.Strata.desktop"
    # GTK 4 liest ohne Settings-Portal (isoliert.py: GDK_DEBUG=no-portals)
    # gsettings nicht; live kommt icon-theme über das Portal. Deshalb steht
    # das Thema hier zusätzlich in settings.ini (Schrift wie isoliert.py).
    schrift=$(gsettings get org.gnome.desktop.interface font-name | tr -d "'")
    mkdir -p "$P/config/gtk-4.0"
    printf '[Settings]\ngtk-font-name=%s\ngtk-icon-theme-name=Querencia\n' "$schrift" >"$P/config/gtk-4.0/settings.ini"
fi
echo "Profil $P ($ART) bereit"
