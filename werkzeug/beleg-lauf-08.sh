#!/bin/bash
# Symbole 0.8: ein isolierter Beleglauf für org.querencia.Dateien, nach
# beleg-lauf-07.sh.
#   beleg-lauf-08.sh <name> ausgang|neu hell|dunkel <BxH> [zeitlimit]
# Bilder nach nachweis/symbole-08/belege/<name>/. Panel und Desktop kommen
# aus den Ablagen, auf die ~/opt/querencia/bin zeigt (nur gelesen; anders
# über PANEL und DESKTOP). Die isolierte Sitzung startet mit bereinigter
# Umgebung (env -i, 13 §5 vom 21.10. 20:38).
set -euo pipefail
R=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
NAME=$1; ART=$2; FARBE=$3; RES=$4; T=${5:-300}
P=$R/gui-test/$NAME; OUT=$R/nachweis/symbole-08/belege/$NAME
PANEL=${PANEL:-$(readlink -f "$HOME/opt/querencia/bin/querencia-panel")}
DESKTOP=${DESKTOP:-$(readlink -f "$HOME/opt/querencia/bin/querencia-desktop")}
bash "$R/werkzeug/beleg-profil-08.sh" "$P" "$ART" "$FARBE"
mkdir -p "$OUT"
cat >"$P/env.sh" <<X
W=$R/werkzeug
Q=$R/werkzeug/bin/qeingabe
QA=$R/werkzeug/bin/qausgabe
OUT=$OUT
RES=$RES
ART=$ART
FARBE=$FARBE
PANEL=$PANEL
DESKTOP=$DESKTOP
export GSK_RENDERER=cairo
X
{
    echo "Lauf $NAME: $ART $FARBE $RES"
    echo "Panel: $PANEL ($(sha256sum "$PANEL" | cut -c1-16))"
    echo "Desktop: $DESKTOP ($(sha256sum "$DESKTOP" | cut -c1-16))"
    echo "Thema im Profil: $(find "$P/data/icons/Querencia" -type f | wc -l) Dateien"
} >"$OUT/lauf.txt"
env -i HOME="$HOME" USER="$USER" LOGNAME="$LOGNAME" PATH="$PATH" LANG="${LANG:-de_DE.UTF-8}" \
    python3 -I "$R/werkzeug/isoliert.py" "$P" "$R/werkzeug/szenario-08.sh" "$T" | tee -a "$OUT/lauf.txt"
cp "$P"/logs/*.log "$OUT/" 2>/dev/null || true
