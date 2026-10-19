#!/bin/bash
# Thema-2: baut integration/thema/vorlage/Querencia (werkzeug/thema-bauen.py)
# zweimal und vergleicht (reproduzierbar), schreibt integration/thema/SHA256SUMS
# und trägt SUMMEN_SHA und DATEIEN in integration/thema-integrieren.sh ein.
# Aufruf: bash thema-vorlage-erzeugen.sh   (liest live nichts)
set -euo pipefail
R=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
T=$R/integration/thema
SKRIPT=$R/integration/thema-integrieren.sh
TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT
python3 -I "$R/werkzeug/thema-bauen.py" "$R/quellen" "$TMP/a"
python3 -I "$R/werkzeug/thema-bauen.py" "$R/quellen" "$TMP/b" >/dev/null
diff -r "$TMP/a" "$TMP/b" >/dev/null || { echo "Bau nicht reproduzierbar" >&2; exit 1; }
[ -z "$(find "$TMP/a" -path '*48x48*' -print -quit)" ]
chmod -R u+w "$T/vorlage" 2>/dev/null || true
rm -rf -- "$T/vorlage"
mkdir -p "$T/vorlage"
cp -r "$TMP/a/Querencia" "$T/vorlage/"
(cd "$T" && find vorlage -type f | LC_ALL=C sort | xargs sha256sum >SHA256SUMS)
chmod -R a-w "$T/vorlage"
summe=$(sha256sum "$T/SHA256SUMS" | cut -d' ' -f1)
anzahl=$(find "$T/vorlage" -type f | wc -l)
sed -i -e "s/^SUMMEN_SHA=.*/SUMMEN_SHA=$summe/" -e "s/^DATEIEN=.*/DATEIEN=$anzahl/" "$SKRIPT"
echo "SUMMEN_SHA=$summe DATEIEN=$anzahl (eingetragen in $SKRIPT)"
