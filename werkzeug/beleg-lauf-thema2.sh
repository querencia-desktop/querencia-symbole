#!/bin/bash
# Thema-2: ein isolierter Beleglauf, nach beleg-lauf.sh (G2-V).
#   beleg-lauf-thema2.sh <name> <szenario> ausgang|thema <BxH> [zeitlimit]
set -euo pipefail
R=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
NAME=$1; SZ=$2; ART=$3; RES=$4; T=${5:-240}
P=$R/gui-test/$NAME; OUT=$R/nachweis/thema2/belege/$NAME
bash "$R/werkzeug/beleg-profil-thema2.sh" "$P" "$ART"
mkdir -p "$OUT"
cat >"$P/env.sh" <<X
W=$R/werkzeug
Q=$R/werkzeug/bin/qeingabe
QA=$R/werkzeug/bin/qausgabe
OUT=$OUT
RES=$RES
ART=$ART
export GSK_RENDERER=cairo
X
python3 -I "$R/werkzeug/isoliert.py" "$P" "$R/werkzeug/$SZ" "$T"
cp "$P"/logs/*.log "$OUT/" 2>/dev/null || true
