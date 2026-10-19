#!/bin/bash
# G2-V: Vorlagen für programm-integrieren.sh aus den Release-Builds der Worktrees.
# integration/vorlage-editor: Binary, Starter (Live-Starter mit neuem Ablagepfad),
# ausgang/ (Live-Starter, nur gelesen), SHA256SUMS; vorlage-systemmonitor: Binary,
# SHA256SUMS. Trägt PROG_NEU und SUMMEN_SHA in programm-integrieren.sh ein.
set -euo pipefail
R=~/projects/querencia-symbole; I=$R/integration; WT=~/projects/querencia-symbole-wt
S=$I/programm-integrieren.sh
for k in editor systemmonitor; do
    d=$I/vorlage-$k; chmod -R u+w "$d" 2>/dev/null || true; rm -rf "$d"; mkdir -p "$d"
    cp "$WT/target-$k/release/querencia-$k" "$d/"
    neu=$(sha256sum "$d/querencia-$k" | cut -d' ' -f1)
    if [ $k = editor ]; then
        mkdir -p "$d/ausgang"
        live=~/.local/share/applications/org.querencia.Editor.desktop
        cp "$live" "$d/ausgang/"
        alt16=$(readlink ~/opt/querencia/bin/querencia-editor | sed -E 's#.*/editor/([0-9a-f]{16})/.*#\1#')
        sed "s#/opt/querencia/editor/$alt16/#/opt/querencia/editor/${neu:0:16}/#g" "$live" >"$d/org.querencia.Editor.desktop"
        desktop-file-validate "$d/org.querencia.Editor.desktop"
        [ "$(diff "$d/ausgang/org.querencia.Editor.desktop" "$d/org.querencia.Editor.desktop" | grep -c '^[<>]')" = 4 ]
    fi
    (cd "$d" && find . -type f ! -name SHA256SUMS | LC_ALL=C sort | xargs sha256sum >SHA256SUMS)
    summen=$(sha256sum "$d/SHA256SUMS" | cut -d' ' -f1)
    K=$(echo $k | tr a-z A-Z)
    sed -i "s/PROG_NEU=@@${K}_NEU@@\$/PROG_NEU=$neu/; s/SUMMEN_SHA=@@${K}_SUMMEN@@\$/SUMMEN_SHA=$summen/" "$S"   # nur Platzhalter ersetzen
    chmod -R a-w "$d"
    echo "$k: PROG_NEU=$neu SUMMEN_SHA=$summen"
done
