#!/bin/bash
# Symbole 0.6: ein isolierter Beleglauf, nach beleg-lauf-thema2.sh.
#   beleg-lauf-06.sh <name> ausgang|neu <BxH> [zeitlimit]
# Bilder nach nachweis/symbole-06/belege/<name>/. BILDER_STARTER wie in
# beleg-profil-06.sh.
set -euo pipefail
R=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
NAME=$1; ART=$2; RES=$3; T=${4:-240}
P=$R/gui-test/$NAME; OUT=$R/nachweis/symbole-06/belege/$NAME
bash "$R/werkzeug/beleg-profil-06.sh" "$P" "$ART"
mkdir -p "$OUT"
cat >"$P/env.sh" <<X
W=$R/werkzeug
Q=$R/werkzeug/bin/qeingabe
QA=$R/werkzeug/bin/qausgabe
OUT=$OUT
RES=$RES
ART=$ART
PDF=~/projects/querencia-dokumente/gui-test/pdf/bericht.pdf
export GSK_RENDERER=cairo
X
python3 -I "$R/werkzeug/isoliert.py" "$P" "$R/werkzeug/szenario-06.sh" "$T"
cp "$P"/logs/*.log "$OUT/" 2>/dev/null || true
