#!/bin/bash
# Symbole 0.8: Wegwerfprofil für die Belegbilder von org.querencia.Dateien
# (isolierter headless labwc), nach beleg-profil-07.sh. Kopiert lesend:
# rc.xml und environment aus querencia-runtime, panel.ini, dconf, alle
# Starter und hicolor des Benutzers; das Thema Querencia kommt aus
# vorlage/alt des Arbeitsordners (Stand 0.7), nie aus dem Live-Ordner;
# GTK-Theme Querencia-Klassisch als Link; gvfs im Wegwerf-Bus nicht
# aktivierbar.
#   beleg-profil-08.sh <profil> ausgang|neu hell|dunkel [<integration-ordner>]
# „neu“: wendet symbole-08-integrieren.sh UMGELENKT (alle vier Umlenkungen)
# auf das Profil an.
# Dazu nur im Profil: der Starter org.querencia.Dateien.desktop der
# Attrappe (werkzeug/dateien-attrappe.py; Name und Kategorie wie Files, damit
# beide Symbole nebeneinander im Menü Zubehör stehen) und eine eigene
# Arbeitsfläche <profil>/arbeitsflaeche mit Kopien der Starter von Dateien
# und Files (user-dirs.dirs des Profils; der echte Schreibtisch bleibt
# unberührt).
# „dunkel“: settings.ini mit gtk-application-prefer-dark-theme (ohne Portal
# der Weg, auf den Panel und Desktop achten), labwc-Theme
# Querencia-Klassisch-Dunkel in der rc.xml-Kopie.
set -euo pipefail
R=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
P=${1:?profil}; ART=${2:?ausgang|neu}; FARBE=${3:?hell|dunkel}
Z=${4:-$HOME/projects/querencia-symbole-08/integration}
case $P in "$R"/gui-test/*) ;; *) echo "Profil nur unter $R/gui-test/" >&2; exit 2 ;; esac
case $ART in ausgang | neu) ;; *) echo "ausgang|neu" >&2; exit 2 ;; esac
case $FARBE in hell | dunkel) ;; *) echo "hell|dunkel" >&2; exit 2 ;; esac
[ ! -e "$P" ] || { echo "Profil $P gibt es schon (Probe löscht nichts)" >&2; exit 2; }
mkdir -p "$P"/{config/labwc,config/querencia,config/dconf,config/gtk-4.0,data/themes,opt/bin,state,logs,arbeitsflaeche}
KONF=${XDG_CONFIG_HOME:-$HOME/.config}; DATEN=${XDG_DATA_HOME:-$HOME/.local/share}
L=${LABWC_VORGABE:-$HOME/projects/querencia-runtime/session/querencia/labwc}
cp "$L/rc.xml" "$L/environment" "$P/config/labwc/"
cp "$KONF/querencia/panel.ini" "$P/config/querencia/"
[ -f "$KONF/dconf/user" ] && cp "$KONF/dconf/user" "$P/config/dconf/"
ln -s "$DATEN/themes/Querencia-Klassisch" "$P/data/themes/Querencia-Klassisch"
ln -s "$DATEN/themes/Querencia-Klassisch-Dunkel" "$P/data/themes/Querencia-Klassisch-Dunkel"
cp -a "$DATEN/applications" "$P/data/applications"
mkdir -p "$P/data/icons"
cp -a "$DATEN/icons/hicolor" "$P/data/icons/"
cp -r "$Z/vorlage/alt/Querencia" "$P/data/icons/"
find "$P/data/icons/Querencia" -type d -exec chmod 0755 {} +
find "$P/data/icons/Querencia" -type f -exec chmod 0644 {} +
mkdir -p "$P/data/dbus-1/services"
for n in $(cd /usr/share/dbus-1/services && ls org.gtk.vfs.*.service | sed 's/\.service$//'); do
    printf '[D-BUS Service]\nName=%s\nExec=/bin/false\n' "$n" >"$P/data/dbus-1/services/$n.service"
done
: >"$P/opt/protokoll.txt"
SYM_OPT=$P/opt SYM_APPS=$P/data/applications SYM_ICONS=$P/data/icons SYM_STATE=$P/state \
    bash "$Z/symbole-08-integrieren.sh" pruefen
if [ "$ART" = neu ]; then
    SYM_OPT=$P/opt SYM_APPS=$P/data/applications SYM_ICONS=$P/data/icons SYM_STATE=$P/state \
        bash "$Z/symbole-08-integrieren.sh" aktivieren
fi
# Starter der Attrappe (nur im Profil)
cat >"$P/data/applications/org.querencia.Dateien.desktop" <<X
[Desktop Entry]
Type=Application
Name=File Browser
Name[de]=Querencia Dateien
Comment=Attrappe für die Symbolbelege (Symbole 0.8)
Exec=python3 -I $R/werkzeug/dateien-attrappe.py 30
TryExec=python3
Icon=org.querencia.Dateien
Terminal=false
Categories=GTK;Utility;FileTools;FileManager;
StartupNotify=true
StartupWMClass=org.querencia.Dateien
X
# eigene Arbeitsfläche mit Starter-Kopien; die übrigen Benutzerordner wie live
sed '/^XDG_DESKTOP_DIR=/d' "$KONF/user-dirs.dirs" >"$P/config/user-dirs.dirs"
echo "XDG_DESKTOP_DIR=\"$P/arbeitsflaeche\"" >>"$P/config/user-dirs.dirs"
cp "$P/data/applications/org.querencia.Dateien.desktop" "$P/arbeitsflaeche/"
cp "$P/data/applications/io.github.lgse.Strata.desktop" "$P/arbeitsflaeche/"
chmod 0755 "$P/arbeitsflaeche"/*.desktop
schrift=$(gsettings get org.gnome.desktop.interface font-name | tr -d "'")
if [ "$FARBE" = dunkel ]; then
    printf '[Settings]\ngtk-font-name=%s\ngtk-icon-theme-name=Querencia\ngtk-theme-name=Querencia-Klassisch\ngtk-application-prefer-dark-theme=1\n' "$schrift" >"$P/config/gtk-4.0/settings.ini"
    sed -i 's#<name>Querencia-Klassisch</name>#<name>Querencia-Klassisch-Dunkel</name>#' "$P/config/labwc/rc.xml"
    grep -q '<name>Querencia-Klassisch-Dunkel</name>' "$P/config/labwc/rc.xml"
else
    printf '[Settings]\ngtk-font-name=%s\ngtk-icon-theme-name=Querencia\ngtk-theme-name=Querencia-Klassisch\n' "$schrift" >"$P/config/gtk-4.0/settings.ini"
fi
echo "Profil $P ($ART, $FARBE) bereit"
