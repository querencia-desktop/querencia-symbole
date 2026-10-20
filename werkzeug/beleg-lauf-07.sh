#!/bin/bash
# Symbole 0.7: ein isolierter Beleglauf, nach beleg-lauf-06.sh.
#   beleg-lauf-07.sh <name> ausgang|neu <BxH> [zeitlimit]
# Bilder nach nachweis/symbole-07/belege/<name>/. Das Panel kommt aus der
# Runtime-Ablage (PANEL, Vorgabe die live laufende G2-AL-Ablage).
set -euo pipefail
R=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
NAME=$1; ART=$2; RES=$3; T=${4:-300}
P=$R/gui-test/$NAME; OUT=$R/nachweis/symbole-07/belege/$NAME
PANEL=${PANEL:-~/opt/querencia/panel/57a015241b32234b/querencia-panel}
bash "$R/werkzeug/beleg-profil-07.sh" "$P" "$ART"
mkdir -p "$OUT"
cat >"$P/env.sh" <<X
W=$R/werkzeug
Q=$R/werkzeug/bin/qeingabe
QA=$R/werkzeug/bin/qausgabe
OUT=$OUT
RES=$RES
ART=$ART
PANEL=$PANEL
export GSK_RENDERER=cairo
X
echo "Panel: $PANEL ($(sha256sum "$PANEL" | cut -c1-16))" >"$OUT/lauf.txt"
python3 -I "$R/werkzeug/isoliert.py" "$P" "$R/werkzeug/szenario-07.sh" "$T" | tee -a "$OUT/lauf.txt"
cp "$P"/logs/*.log "$OUT/" 2>/dev/null || true
