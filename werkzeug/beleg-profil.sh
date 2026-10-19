#!/bin/bash
# G2-V: Wegwerfprofil für die Belegbilder (isolierter headless labwc).
# Kopiert lesend: rc.xml, environment, panel.ini, dconf, Starter und
# hicolor des Benutzers; Theme Querencia-Klassisch als Link. Mit „nachher“
# wird symbole-integrieren.sh UMGELENKT auf das Profil angewandt.
#   beleg-profil.sh <profil> vorher|nachher
set -euo pipefail
P=${1:?profil}; ART=${2:?vorher|nachher}
case $P in ~/projects/querencia-symbole/gui-test/*) ;; *) echo "Profil nur unter gui-test/" >&2; exit 2 ;; esac
[ -e "$P" ] && { chmod -R u+rwX "$P"; rm -rf "$P"; }
mkdir -p "$P"/{config/labwc,config/querencia,config/dconf,data/themes,opt/bin,state,logs}
L=~/projects/querencia-runtime/session/querencia/labwc
cp "$L/rc.xml" "$L/environment" "$P/config/labwc/"
cp ~/.config/querencia/panel.ini "$P/config/querencia/"
[ -f ~/.config/dconf/user ] && cp ~/.config/dconf/user "$P/config/dconf/"
ln -s ~/.local/share/themes/Querencia-Klassisch "$P/data/themes/Querencia-Klassisch"
cp -a ~/.local/share/applications "$P/data/applications"
mkdir -p "$P/data/icons"; cp -a ~/.local/share/icons/hicolor "$P/data/icons/"
if [ "$ART" = nachher ]; then
    SYM_OPT=$P/opt SYM_APPS=$P/data/applications SYM_ICONS=$P/data/icons SYM_STATE=$P/state \
        bash ~/projects/querencia-symbole/integration/symbole-integrieren.sh aktivieren
fi
echo "Profil $P ($ART) bereit"
