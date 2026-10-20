#!/bin/bash
# Probe für symbole-integrieren-0.6.sh gegen umgelenkte Pfade, immer mit
# allen vier Umlenkungen SYM_OPT SYM_APPS SYM_ICONS SYM_STATE. Jeder Fall
# bekommt ein eigenes Probe-HOME; dort laufen auch dokumente-010-integrieren.sh
# (HOME umgelenkt) und thema-integrieren.sh (THM_OPT THM_ICONS THM_STATE).
#   Sperre  live ohne SYM_FREIGABE, halbe Umlenkungen → verweigert
#   A  Live-Stand heute: Dokumente 0.1.0 aktiv, Thema 0.1 → aktivieren →
#      Dokumente-/Thema-Skript sehen „fremd“ und verweigern → zurueck-0.5.2 →
#      beide sehen wieder „neu“ → Dokumente zurueck → 0.6 sieht Hicolor=fehlt
#   B  Dokumente nicht installiert: aktivieren nur Thema → Dokumente
#      aktivieren → aktivieren ersetzt dessen Symbol → zurueck-0.5.2
#   E  künstliche Fehler und Signale an jeder Stelle → Baum byte-gleich
#   F  fremde Stände, verfälschte Vorlage, belegte Sperren → verweigert
# symbole-integrieren-0.5.2.sh pruefen bleibt in allen Fällen gleich (0.6
# fasst dessen Dateien nicht an). Live wird nur gelesen. Die Probe löscht
# nichts (neue Unterordner, Beiseitelegen nach <arbeit>/weg/).
# Aufruf: bash symbole-probe-0.6.sh <neuer, leerer Arbeitsordner>
set -uo pipefail
I=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../integration" && pwd -P)
SKRIPT=${PROBE_SKRIPT:-$I/symbole-integrieren-0.6.sh}
S052=$I/symbole-integrieren-0.5.2.sh
THM=$I/thema-integrieren.sh
DOK=${DOK_SKRIPT:-~/projects/querencia-dokumente/integration/werkzeug/dokumente-010-integrieren.sh}
W=${1:?Arbeitsordner}
[ ! -e "$W" ] || [ -z "$(ls -A "$W")" ] || { echo "Arbeitsordner $W ist nicht leer" >&2; exit 2; }
mkdir -p "$W/weg"
W=$(cd "$W" && pwd -P)
PASS=0; FAIL=0
ok()  { echo "PASS $*"; PASS=$((PASS+1)); }
nok() { echo "FAIL $*"; FAIL=$((FAIL+1)); }
NAME=org.querencia.Dokumente

# Probe-HOME: hicolor = Vorlage 0.5.2, Querencia = Thema-Vorlage 0.1 (Rechte
# wie thema-integrieren.sh), Starter der Thema-2-Programme aus dem Live-Stand
# (nur gelesen), Journal leer.
baum() {
    local h=$W/$1/home
    mkdir -p "$h"/{opt/querencia/bin,.local/share/icons,.local/share/applications,.local/state/querencia,.config} || exit 2
    cp -r "$I/vorlage/icons/hicolor" "$h/.local/share/icons/"
    cp -r "$I/thema/vorlage/Querencia" "$h/.local/share/icons/"
    find "$h/.local/share/icons" -type d -exec chmod 0755 {} +
    find "$h/.local/share/icons" -type f -exec chmod 0644 {} +
    tar -C ~/.local/share/applications -cf - --exclude="./$NAME.desktop" --exclude=./mimeinfo.cache . | tar -C "$h/.local/share/applications" -xf -
    : >"$h/opt/querencia/protokoll.txt"
}
nutze() {
    H=$W/$1/home; B=$H/.local/share
    export SYM_OPT=$H/opt/querencia SYM_APPS=$B/applications SYM_ICONS=$B/icons SYM_STATE=$H/.local/state/querencia
    export THM_OPT=$SYM_OPT THM_ICONS=$SYM_ICONS THM_STATE=$SYM_STATE
}
beiseite() { mv -- "$1" "$W/weg/$(date +%s%N)-$(basename -- "$1")"; }
dok() { HOME=$H bash "$DOK" "$@"; }
# Stand: Prüfsummen, Rechte und Ordner der Symbolbäume und Starter, dazu mimeapps.list
stand() { (cd "$B" && find icons applications -type f ! -name mimeinfo.cache -exec sha256sum {} + | LC_ALL=C sort; find icons -type d | LC_ALL=C sort; find icons applications -type f -exec stat -c '%a %n' {} + | LC_ALL=C sort; sha256sum "$H/.config/mimeapps.list" 2>/dev/null); }
zust() { bash "$SKRIPT" pruefen 2>&1 | grep -E '^symbole-integrieren: (Hicolor|Thema) ' | grep -oE ': (alt|neu|fremd|fehlt)$' | awk '{print $2}' | tr '\n' ' ' | sed 's/ $//'; }
thm_zust() { bash "$THM" pruefen 2>&1 | grep -E '^thema-integrieren: Thema ' | grep -oE ': (alt|neu|fremd)$' | awk '{print $2}'; }
dok_s() { dok pruefen 2>&1 | grep -E '^dokumente-integrieren: S ' | grep -oE ': (alt|neu|fremd)$' | awk '{print $2}'; }
s052() { bash "$S052" pruefen 2>&1; }
lauf() { local erw=$1; shift; out=$("$@" 2>&1); rc=$?; echo "$out" | sed 's/^/    /'; [ "$rc" = "$erw" ] && ok "[$FALL] ${*: -1} → Exit $rc" || nok "[$FALL] ${*: -1} → Exit $rc (erwartet $erw)"; }
kurz() { [ "$(printf '%s\n' "$1" | wc -l)" -le 1 ] && printf '%s' "$1" || printf '%s Zeilen, sha %s' "$(printf '%s\n' "$1" | wc -l)" "$(printf '%s' "$1" | sha256sum | cut -c1-12)"; }
pruef() { [ "$1" = "$2" ] && ok "[$FALL] $3: $(kurz "$1")" || nok "[$FALL] $3: $(kurz "$1") (erwartet $(kurz "$2"))"; }
fehler() { # befehl soll-stand stellen…
    local cmd=$1 soll=$2 f; shift 2
    for f in "$@"; do
        SYM_PROBE=1 SYM_FEHLER=$f lauf 1 bash "$SKRIPT" "$cmd"
        [ "$(stand)" = "$soll" ] && ok "[$FALL] Fehler $f bei $cmd: Baum byte-gleich" || { nok "[$FALL] Fehler $f bei $cmd: Baum verändert"; diff <(echo "$soll") <(stand) | head; }
        [ -z "$(find "$B/icons" -name '*.sym-tmp' -print -quit)" ] && ok "[$FALL] Fehler $f: keine Hilfsdatei übrig" || nok "[$FALL] Fehler $f: Hilfsdatei übrig"
    done
}
kein48() { [ -z "$(find "$B/icons" -path '*48x48*' -name "$NAME.*" -print -quit)" ]; }
gleich_neu() { local g f; for g in 16x16 22x22 24x24 32x32 64x64 128x128 256x256 scalable; do
    [ $g = scalable ] && f=$g/apps/$NAME.svg || f=$g/apps/$NAME.png
    cmp -s "$I/vorlage-0.6/neu/$f" "$1/$f" || return 1; done; }

echo "################ Sperren"
FALL=Sperre
for cmd in aktivieren zurueck-0.5.2; do
    env -u SYM_OPT -u SYM_APPS -u SYM_ICONS -u SYM_STATE -u SYM_FREIGABE bash "$SKRIPT" $cmd >/dev/null 2>&1; rc=$?
    [ $rc = 2 ] && ok "[Sperre] live $cmd ohne SYM_FREIGABE → Exit 2" || nok "[Sperre] live $cmd ohne SYM_FREIGABE → Exit $rc"
done
for teil in "SYM_OPT" "SYM_OPT SYM_APPS" "SYM_OPT SYM_APPS SYM_ICONS" "SYM_ICONS SYM_STATE"; do
    args=(); for v in SYM_OPT SYM_APPS SYM_ICONS SYM_STATE; do args+=(-u "$v"); done
    setz=(); for v in $teil; do setz+=("$v=$W/halb/$v"); done
    env "${args[@]}" "${setz[@]}" SYM_FREIGABE=ja bash "$SKRIPT" aktivieren >/dev/null 2>&1; rc=$?
    [ $rc = 2 ] && ok "[Sperre] nur $teil umgelenkt → Exit 2" || nok "[Sperre] nur $teil umgelenkt → Exit $rc"
done
[ ! -e "$W/halb" ] && ok "[Sperre] halbe Umlenkung legte nichts an" || nok "[Sperre] halbe Umlenkung legte $W/halb an"
env -u SYM_OPT -u SYM_APPS -u SYM_ICONS -u SYM_STATE bash "$SKRIPT" unsinn >/dev/null 2>&1; rc=$?
pruef "$rc" 2 "unbekannter Befehl"

echo "################ A: Live-Stand heute (Dokumente 0.1.0 aktiv, Thema 0.1)"
FALL=A
baum A; nutze A
lauf 0 dok aktivieren
pruef "$(dok_s)" neu "Dokumente S nach dessen aktivieren"
pruef "$(zust)" "alt alt" "0.6 vorher"
pruef "$(thm_zust)" neu "Thema-Skript vorher"
V052=$(s052)
lauf 0 bash "$SKRIPT" pruefen
VOR_A=$(stand)
STARTER_VOR=$(sha256sum "$B/applications/$NAME.desktop")
lauf 0 bash "$SKRIPT" aktivieren
pruef "$(zust)" "neu neu" "0.6 nach aktivieren"
gleich_neu "$B/icons/hicolor" && ok "[A] hicolor byte-gleich vorlage-0.6/neu" || nok "[A] hicolor weicht ab"
gleich_neu "$B/icons/Querencia" && ok "[A] Querencia byte-gleich vorlage-0.6/neu" || nok "[A] Querencia weicht ab"
kein48 && ok "[A] kein 48x48" || nok "[A] 48x48 vorhanden"
[ -z "$(find "$B/icons/Querencia" -name "$NAME.*" ! -perm 0644)" ] && ok "[A] Thema-Dateien 0644" || nok "[A] Thema-Dateien nicht 0644"
pruef "$(s052)" "$V052" "0.5.2 pruefen unverändert"
pruef "$(sha256sum "$B/applications/$NAME.desktop")" "$STARTER_VOR" "Dokumente-Starter unangetastet"
grep -q "zurueck-0.5.2" "$SYM_OPT/protokoll.txt" && grep -q "$SKRIPT zurueck-0.5.2" "$SYM_OPT/protokoll.txt" && ok "[A] Journal nennt Rückfall mit dieser Datei" || nok "[A] Journalzeile fehlt"
NACH_A=$(stand)
lauf 0 bash "$SKRIPT" aktivieren
pruef "$(stand)" "$NACH_A" "zweites aktivieren ändert nichts"
pruef "$(dok_s)" fremd "Dokumente S bei 0.6 aktiv"
pruef "$(thm_zust)" fremd "Thema-Skript bei 0.6 aktiv"
lauf 2 dok zurueck
lauf 2 env THM_FREIGABE= bash "$THM" zurueck
pruef "$(stand)" "$NACH_A" "Verweigerungen änderten nichts"
lauf 0 bash "$SKRIPT" zurueck-0.5.2
pruef "$(zust)" "alt alt" "0.6 nach zurueck-0.5.2"
pruef "$(stand)" "$VOR_A" "Baum wie vor aktivieren"
pruef "$(dok_s)" neu "Dokumente S nach zurueck-0.5.2"
pruef "$(thm_zust)" neu "Thema-Skript nach zurueck-0.5.2"
pruef "$(s052)" "$V052" "0.5.2 pruefen unverändert"
lauf 0 bash "$SKRIPT" zurueck-0.5.2
pruef "$(stand)" "$VOR_A" "zweites zurueck-0.5.2 ändert nichts"
lauf 0 dok zurueck
pruef "$(zust)" "fehlt alt" "0.6 nach Dokumente zurueck"

echo "################ B: Dokumente nicht installiert"
FALL=B
baum B; nutze B
pruef "$(zust)" "fehlt alt" "0.6 vorher"
lauf 0 bash "$SKRIPT" aktivieren
pruef "$(zust)" "fehlt neu" "nur Thema"
[ -z "$(find "$B/icons/hicolor" -name "$NAME.*" -print -quit)" ] && ok "[B] hicolor ohne Dokumente-Symbol" || nok "[B] hicolor hat Dokumente-Symbol"
lauf 0 bash "$SKRIPT" aktivieren
lauf 0 dok aktivieren
pruef "$(zust)" "alt neu" "nach Dokumente aktivieren"
lauf 0 bash "$SKRIPT" aktivieren
pruef "$(zust)" "neu neu" "zweites 0.6 aktivieren"
lauf 0 bash "$SKRIPT" zurueck-0.5.2
pruef "$(zust)" "alt alt" "nach zurueck-0.5.2"
pruef "$(dok_s)" neu "Dokumente S"

echo "################ E: Fehler und Signale"
FALL=E
baum E; nutze E
lauf 0 dok aktivieren
SOLL=$(stand)
fehler aktivieren "$SOLL" vor-erstem Thema-16x16 Thema-128x128 Thema-scalable nach-thema Hicolor-16x16 Hicolor-64x64 Hicolor-scalable nach-touch \
    signal-vor-erstem signal-Thema-22x22 signal-nach-thema signal-Hicolor-24x24 signal-Hicolor-scalable signal-nach-touch
pruef "$(zust)" "alt alt" "nach allen Fehlern bei aktivieren"
lauf 0 bash "$SKRIPT" aktivieren
SOLL=$(stand)
fehler zurueck-0.5.2 "$SOLL" vor-erstem Hicolor-16x16 Hicolor-256x256 Hicolor-scalable nach-hicolor Thema-32x32 Thema-scalable nach-touch \
    signal-Hicolor-128x128 signal-nach-hicolor signal-Thema-16x16 signal-nach-touch
pruef "$(zust)" "neu neu" "nach allen Fehlern bei zurueck-0.5.2"
grep -q 'abgebrochen' "$SYM_OPT/protokoll.txt" && ok "[E] Journal vermerkt Abbrüche" || nok "[E] Abbrüche fehlen im Journal"

echo "################ F: fremde Stände, Vorlage, Sperren"
FALL=F
verweigert() { # Beschreibung Befehl
    local vor; vor=$(stand)
    lauf 2 bash "$SKRIPT" "$2"
    [ "$(stand)" = "$vor" ] && ok "[F] $1: nichts geändert" || nok "[F] $1: Baum verändert"
}
baum F1; nutze F1; lauf 0 dok aktivieren
printf x >>"$B/icons/hicolor/16x16/apps/$NAME.png"
verweigert "hicolor-PNG verändert" aktivieren
pruef "$(zust)" "fremd alt" "Zustand"
baum F2; nutze F2; lauf 0 dok aktivieren
cp "$B/icons/hicolor/64x64/apps/$NAME.png" "$B/icons/hicolor/48x48/apps/$NAME.png" 2>/dev/null || { mkdir -p "$B/icons/hicolor/48x48/apps"; cp "$B/icons/hicolor/64x64/apps/$NAME.png" "$B/icons/hicolor/48x48/apps/$NAME.png"; }
verweigert "48x48 in hicolor" aktivieren
baum F3; nutze F3; lauf 0 dok aktivieren
beiseite "$B/icons/hicolor/22x22/apps/$NAME.png"
verweigert "hicolor unvollständig" aktivieren
baum F4; nutze F4; lauf 0 dok aktivieren
cp "$I/vorlage-0.6/neu/16x16/apps/$NAME.png" "$B/icons/Querencia/16x16/apps/"; chmod 0644 "$B/icons/Querencia/16x16/apps/$NAME.png"
verweigert "Thema mit einer von acht Dateien" aktivieren
baum F5; nutze F5; lauf 0 dok aktivieren
: >"$B/icons/Querencia/16x16/apps/fremd.png"; chmod 0644 "$B/icons/Querencia/16x16/apps/fremd.png"
verweigert "Thema mit fremder Datei" aktivieren
pruef "$(zust)" "alt fremd" "Zustand"
baum F6; nutze F6; lauf 0 dok aktivieren
chmod 0600 "$B/icons/Querencia/index.theme"
verweigert "Thema mit anderen Rechten" aktivieren
baum F7; nutze F7; lauf 0 dok aktivieren
beiseite "$B/icons/Querencia"
verweigert "Thema fehlt" aktivieren
lauf 0 bash "$SKRIPT" zurueck-0.5.2
baum F8; nutze F8; lauf 0 dok aktivieren; lauf 0 bash "$SKRIPT" aktivieren
printf x >>"$B/icons/Querencia/scalable/apps/$NAME.svg"
verweigert "Thema-SVG nach 0.6 verändert" zurueck-0.5.2
# Sperren der drei Skripte
baum F9; nutze F9; lauf 0 dok aktivieren
for l in symbole-integrieren dokumente-integrieren thema-integrieren; do
    flock "$SYM_STATE/$l.lock" sleep 30 & sp=$!
    sleep 0.5
    verweigert "$l.lock belegt" aktivieren
    kill $sp 2>/dev/null; wait $sp 2>/dev/null
done
# verfälschte Vorlage (Kopie des integration-Ordners)
mkdir "$W/kopie"; cp -r "$I/symbole-integrieren-0.6.sh" "$I/vorlage-0.6" "$I/thema" "$W/kopie/"; chmod -R u+w "$W/kopie"
SKRIPT_ECHT=$SKRIPT; SKRIPT=$W/kopie/symbole-integrieren-0.6.sh
lauf 0 bash "$SKRIPT" pruefen
printf x >>"$W/kopie/vorlage-0.6/neu/32x32/apps/$NAME.png"
verweigert "Vorlage verfälscht" aktivieren
cp "$I/vorlage-0.6/neu/32x32/apps/$NAME.png" "$W/kopie/vorlage-0.6/neu/32x32/apps/$NAME.png"
echo "# x" >>"$W/kopie/vorlage-0.6/SHA256SUMS"
verweigert "SHA256SUMS verfälscht" aktivieren
SKRIPT=$SKRIPT_ECHT

echo "################ Ergebnis: $PASS PASS, $FAIL FAIL"
[ "$FAIL" = 0 ]
