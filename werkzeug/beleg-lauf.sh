#!/bin/bash
# G2-V: ein isolierter Lauf. beleg-lauf.sh <name> <szenario> <vorher|nachher> <BxH> [zeitlimit]
set -euo pipefail
R=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
NAME=$1; SZ=$2; ART=$3; RES=$4; T=${5:-180}
P=$R/gui-test/$NAME; OUT=$R/nachweis/belege/$NAME
bash "$R/werkzeug/beleg-profil.sh" "$P" "$ART"
mkdir -p "$OUT"
cat >"$P/env.sh" <<X
W=$R/werkzeug
Q=$R/werkzeug/bin/qeingabe
QA=$R/werkzeug/bin/qausgabe
OUT=$OUT
RES=$RES
ART=$ART
EDITOR_BIN=\${EDITOR_BIN:-\$HOME/opt/querencia/bin/querencia-editor}
SYSMON_BIN=\${SYSMON_BIN:-\$HOME/opt/querencia/bin/querencia-systemmonitor}
export GSK_RENDERER=cairo
X
python3 -I "$R/werkzeug/isoliert.py" "$P" "$R/werkzeug/$SZ" "$T"
cp "$P"/logs/*.log "$OUT/" 2>/dev/null || true
