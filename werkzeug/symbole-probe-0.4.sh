#!/bin/bash
# Probe für symbole-integrieren.sh 0.4 gegen umgelenkte Pfade (Thema-2), immer
# mit allen vier Umlenkungen SYM_OPT SYM_APPS SYM_ICONS SYM_STATE:
#   Sperre  live ohne SYM_FREIGABE, halbe Umlenkungen → verweigert
#   A  Ausgang 19.10. ~10:00 (aus integration/ausgang nachgebaut) → aktivieren
#      → zurueck-0.4 → zurueck-0.3 → zurueck, mit Fehlerstellen und Signalen
#   B  heutiger Live-Stand (vollständige Kopie: G2-V und Thema-2-Symbole 0.3
#      aktiv, Starter alt; org.querencia.Terminal.desktop, falls die
#      App-ID-Session ihn schon live hat) → aktivieren (nur Icon=-Zeilen) →
#      zurueck-0.4 (byte-gleich Live-Stand) → zurueck-0.3 → zurueck
#   T  ohne neuen Terminal-Starter kopiert, dann wie die App-ID-Session ihn
#      anlegt (Brücke NoDisplay=true) → beide Starter; Starter, der erst nach
#      der Aktivierung kommt
#   F  fremde Stände (Symbol einer anderen Session, 48x48, fremde Icon=-Werte,
#      Link statt Starter) → verweigert, nichts geändert
# In Startern ändert sich immer nur die Icon=-Zeile. Live wird nur gelesen.
# Die Probe selbst löscht nichts: jeder Fall bekommt einen neuen Unterordner
# des (leeren) Arbeitsordners, Beiseitegelegtes wandert nach <arbeit>/weg/.
# Aufruf: bash symbole-probe-0.4.sh <neuer, leerer Arbeitsordner>
set -uo pipefail
I=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../integration" && pwd -P)
SKRIPT=$I/symbole-integrieren.sh
W=${1:?Arbeitsordner}
[ ! -e "$W" ] || [ -z "$(ls -A "$W")" ] || { echo "Arbeitsordner $W ist nicht leer" >&2; exit 2; }
mkdir -p "$W/weg"
PASS=0; FAIL=0
ok()  { echo "PASS $*"; PASS=$((PASS+1)); }
nok() { echo "FAIL $*"; FAIL=$((FAIL+1)); }
NEU4="org.querencia.Files io.github.lgse.Strata org.querencia.Terminal org.querencia.Screenshot"
TB=org.example.Querencia.Terminal.desktop; SS=org.querencia.Screenshot.desktop; TN=org.querencia.Terminal.desktop
# Name [Ausschlussliste] [ohne-tn] → Kopie des Live-Stands (nur gelesen) in
# einem neuen Ordner; mit „ohne-tn“ bleibt ein schon live angelegter neuer
# Terminal-Starter draußen (A: Stand 19.10., T: legt ihn selbst an).
baum() {
    local b=$W/$1 aus=${2:-/dev/null} tn=./kein-ausschluss
    [ "${3:-}" = ohne-tn ] && tn=./$TN
    mkdir "$b" || exit 2
    mkdir -p "$b"/{opt/bin,icons,state,apps}
    tar -C ~/.local/share/icons -cf - --exclude-from="$aus" hicolor | tar -C "$b/icons" -xf -
    tar -C ~/.local/share/applications -cf - --exclude="$tn" . | tar -C "$b/apps" -xf -
}
beiseite() { mv -- "$1" "$W/weg/$(date +%s%N)-$(basename -- "$1")"; }
nutze() { export SYM_OPT=$W/$1/opt SYM_APPS=$W/$1/apps SYM_ICONS=$W/$1/icons SYM_STATE=$W/$1/state; B=$W/$1; }
stand() { (cd "$B" && find icons apps -type f -exec sha256sum {} + | LC_ALL=C sort; find icons apps -type d | LC_ALL=C sort); }
starter() { (cd "$B/apps" && find . -type f -name '*.desktop' -exec sha256sum {} + | LC_ALL=C sort); }
zust() { bash "$SKRIPT" pruefen 2>&1 | grep -v ': alt = Ausgang' | grep -oE ': (alt|neu|fremd|fehlt)( |$)' | awk '{print $2}' | tr '\n' ' ' | sed 's/ $//'; }
lauf() { local erw=$1; shift; out=$("$@" 2>&1); rc=$?; echo "$out" | sed 's/^/    /'; [ "$rc" = "$erw" ] && ok "[$FALL] ${*: -1} → Exit $rc" || nok "[$FALL] ${*: -1} → Exit $rc (erwartet $erw)"; }
fehler() { # befehl soll-stand stellen…
    local cmd=$1 soll=$2 f; shift 2
    for f in "$@"; do
        SYM_PROBE=1 SYM_FEHLER=$f lauf 1 bash "$SKRIPT" "$cmd"
        [ "$(stand)" = "$soll" ] && ok "[$FALL] Fehler $f bei $cmd: Baum byte-gleich" || { nok "[$FALL] Fehler $f bei $cmd: Baum verändert"; diff <(echo "$soll") <(stand) | head; }
    done
}
# Zustandszeile: 6× G2-V, 4× Thema-2-Symbole, Einstellungen-Starter,
# TerminalStarter, TerminalBruecke und ScreenshotStarter
Z() { echo "$1 $1 $1 $1 $1 $1 $2 $2 $2 $2 $3 $4 $5 $5"; }
# Starter dürfen sich nur in der Icon=-Zeile unterscheiden: a b neuer-Wert
nur_icon() { local d; d=$(diff "$1" "$2" | grep '^[<>]'); [ "$(echo "$d" | wc -l)" = 2 ] && echo "$d" | grep -qx "> Icon=$3"; }
kein48() { [ -z "$(find "$B/icons/hicolor" -path '*48x48*' \( -name 'org.querencia.*' -o -name 'io.github.lgse.Strata.*' \))" ]; }

echo "################ Sperren"
FALL=Sperre
for cmd in aktivieren zurueck zurueck-0.3 zurueck-0.4; do
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

echo "################ A: Ausgang 19.10. → aktivieren → zurueck-0.4 → zurueck-0.3 → zurueck"
FALL=A
# Ausgang: Vorlage-Dateien, die es im Ausgang nicht gab, gar nicht erst kopieren
(cd "$I/vorlage/icons" && find hicolor -type f | while read -r rel; do [ -e "$I/ausgang/icons/$rel" ] || echo "$rel"; done) >"$W/ohne-ausgang.txt"
baum A "$W/ohne-ausgang.txt" ohne-tn; nutze A
(cd "$I/ausgang" && find icons -type f) | while read -r rel; do cp -p "$I/ausgang/$rel" "$B/$rel"; done
cp -p "$I/ausgang/applications/org.querencia.Einstellungen.desktop" "$B/apps/"
cp -p "$B/apps/$TB" "$W/a-tb.desktop"; cp -p "$B/apps/$SS" "$W/a-ss.desktop"
AUSGANG=$(stand)
[ "$(zust)" = "$(Z alt alt alt fehlt alt)" ] && ok "[A] Ausgang: alt, TerminalStarter fehlt" || nok "[A] Ausgang $(zust)"
fehler aktivieren "$AUSGANG" vor-erstem Systemmonitor-16x16 Lautstaerke-64x64 Files-16x16 Strata-scalable Screenshot-256x256 nach-symbolen Starter TerminalBruecke ScreenshotStarter nach-touch signal-Terminal-64x64 signal-Starter signal-ScreenshotStarter
lauf 0 bash "$SKRIPT" aktivieren
[ "$(zust)" = "$(Z neu neu neu fehlt neu)" ] && ok "[A] nach aktivieren neu, TerminalStarter fehlt weiter" || nok "[A] nach aktivieren $(zust)"
[ ! -e "$B/apps/$TN" ] && ok "[A] fehlender Terminal-Starter nicht angelegt" || nok "[A] Terminal-Starter angelegt"
nur_icon "$W/a-tb.desktop" "$B/apps/$TB" org.querencia.Terminal && ok "[A] Brücke: nur Icon= → org.querencia.Terminal" || nok "[A] Brücke: mehr als Icon= geändert"
nur_icon "$W/a-ss.desktop" "$B/apps/$SS" org.querencia.Screenshot && ok "[A] Screenshot: nur Icon= → org.querencia.Screenshot" || nok "[A] Screenshot: mehr als Icon= geändert"
kein48 && ok "[A] kein 48x48" || nok "[A] 48x48"
for n in $NEU4; do
    cmp -s "$B/icons/hicolor/scalable/apps/$n.svg" "$I/vorlage/icons/hicolor/scalable/apps/$n.svg" && ok "[A] $n.svg = Vorlage" || nok "[A] $n.svg fehlt/abweichend"
done
NEU=$(stand)
lauf 0 bash "$SKRIPT" aktivieren
[ "$(stand)" = "$NEU" ] && ok "[A] zweites aktivieren: nichts geändert" || nok "[A] zweites aktivieren änderte"
fehler zurueck-0.4 "$NEU" vor-erstem TerminalBruecke signal-ScreenshotStarter nach-touch
lauf 0 bash "$SKRIPT" zurueck-0.4
[ "$(zust)" = "$(Z neu neu neu fehlt alt)" ] && ok "[A] zurueck-0.4: nur die Starter-Zeilen alt" || nok "[A] zurueck-0.4: $(zust)"
cmp -s "$W/a-tb.desktop" "$B/apps/$TB" && cmp -s "$W/a-ss.desktop" "$B/apps/$SS" && ok "[A] zurueck-0.4: Brücke und Screenshot byte-gleich Ausgang" || nok "[A] zurueck-0.4: Starter abweichend"
lauf 0 bash "$SKRIPT" zurueck-0.4
lauf 0 bash "$SKRIPT" aktivieren
NEU=$(stand)
fehler zurueck-0.3 "$NEU" Files-16x16 Strata-128x128 signal-Terminal-scalable Screenshot-22x22 TerminalBruecke signal-ScreenshotStarter nach-touch
lauf 0 bash "$SKRIPT" zurueck-0.3
[ "$(zust)" = "$(Z neu alt neu fehlt alt)" ] && ok "[A] zurueck-0.3: G2-V neu, Thema-2 alt" || nok "[A] zurueck-0.3: $(zust)"
rest=0; for n in $NEU4; do [ -z "$(find "$B/icons" -name "$n.*" -print -quit)" ] || rest=1; done
[ $rest = 0 ] && ok "[A] zurueck-0.3: keine Datei der vier Namen mehr" || nok "[A] nach zurueck-0.3 noch Dateien der vier Namen"
lauf 0 bash "$SKRIPT" zurueck-0.3
fehler zurueck "$(stand)" Starter signal-Starter Editor-scalable Lautstaerke-16x16 signal-Sitzung-22x22
lauf 0 bash "$SKRIPT" zurueck
[ "$(stand)" = "$AUSGANG" ] && ok "[A] zurueck: byte-gleich Ausgang (Dateien, Ordner)" || { nok "[A] zurueck weicht ab"; diff <(echo "$AUSGANG") <(stand); }
lauf 0 bash "$SKRIPT" aktivieren
fehler zurueck "$(stand)" Files-scalable signal-Strata-16x16 Starter ScreenshotStarter signal-TerminalBruecke
lauf 0 bash "$SKRIPT" zurueck
[ "$(stand)" = "$AUSGANG" ] && ok "[A] zurueck aus voll aktiv: byte-gleich Ausgang" || { nok "[A] zurueck aus voll aktiv weicht ab"; diff <(echo "$AUSGANG") <(stand); }
A_AUSGANG=$AUSGANG

echo "################ B: heutiger Live-Stand → aktivieren → zurueck-0.4 → zurueck-0.3 → zurueck"
FALL=B; baum B; nutze B
LIVE=$(stand); ST0=$(starter)
cp -p "$B/apps/$TB" "$W/b-tb.desktop"; cp -p "$B/apps/$SS" "$W/b-ss.desktop"
if [ -e "$B/apps/$TN" ]; then TSA=alt; TSN=neu; ANZ=3; cp -p "$B/apps/$TN" "$W/b-tn.desktop"; else TSA=fehlt; TSN=fehlt; ANZ=2; fi
echo "## neuer Terminal-Starter live: $TSA"
[ "$(zust)" = "$(Z neu neu neu $TSA alt)" ] && ok "[B] Live-Stand: Symbole neu, Starter alt (TerminalStarter $TSA)" || nok "[B] Live-Stand $(zust)"
fehler aktivieren "$LIVE" vor-erstem TerminalBruecke ScreenshotStarter signal-TerminalBruecke nach-touch
lauf 0 bash "$SKRIPT" aktivieren
[ "$(zust)" = "$(Z neu neu neu $TSN neu)" ] && ok "[B] nach aktivieren: alle vorhandenen Starter neu" || nok "[B] nach aktivieren $(zust)"
D=$(diff <(echo "$LIVE") <(stand) | grep '^[<>]')
[ -z "$(echo "$D" | grep '  icons/')" ] && ok "[B] aktivieren: keine Symboldatei geändert" || nok "[B] aktivieren änderte Symbole"
[ "$(echo "$D" | grep -c '^>')" = $ANZ ] && echo "$D" | grep '^>' | grep -q "apps/$TB\$" && echo "$D" | grep '^>' | grep -q "apps/$SS\$" && ok "[B] aktivieren: genau $ANZ Terminal-/Screenshot-Starter geändert" || { nok "[B] aktivieren: andere Änderungen"; echo "$D"; }
nur_icon "$W/b-tb.desktop" "$B/apps/$TB" org.querencia.Terminal && nur_icon "$W/b-ss.desktop" "$B/apps/$SS" org.querencia.Screenshot && ok "[B] nur die Icon=-Zeilen geändert (Screenshot-0.2.6-Stand sonst gleich)" || nok "[B] mehr als Icon= geändert"
if [ $TSA = alt ]; then nur_icon "$W/b-tn.desktop" "$B/apps/$TN" org.querencia.Terminal && ok "[B] neuer Terminal-Starter: nur Icon=" || nok "[B] neuer Terminal-Starter: mehr als Icon="; fi
ungueltig=0; for s in $TB $SS $TN; do [ -e "$B/apps/$s" ] || continue; desktop-file-validate "$B/apps/$s" >/dev/null || ungueltig=1; done
[ $ungueltig = 0 ] && ok "[B] Starter gültig (desktop-file-validate)" || nok "[B] Starter ungültig"
NEU=$(stand)
lauf 0 bash "$SKRIPT" zurueck-0.4
[ "$(stand)" = "$LIVE" ] && ok "[B] zurueck-0.4: byte-gleich Live-Stand" || { nok "[B] zurueck-0.4 weicht ab"; diff <(echo "$LIVE") <(stand) | head; }
lauf 0 bash "$SKRIPT" aktivieren
[ "$(stand)" = "$NEU" ] && ok "[B] erneut aktivieren: byte-gleich wie zuvor" || nok "[B] erneut aktivieren weicht ab"
lauf 0 bash "$SKRIPT" zurueck-0.3
[ "$(zust)" = "$(Z neu alt neu $TSA alt)" ] && ok "[B] zurueck-0.3: Thema-2 ganz zurück" || nok "[B] zurueck-0.3: $(zust)"
cmp -s "$W/b-tb.desktop" "$B/apps/$TB" && cmp -s "$W/b-ss.desktop" "$B/apps/$SS" && ok "[B] zurueck-0.3: Starter byte-gleich Live" || nok "[B] zurueck-0.3: Starter abweichend"
lauf 0 bash "$SKRIPT" zurueck
# Live-Starter anderer Programme können sich zwischen den Kopien A und B ändern
# (parallele Sessions); verglichen werden darum die Symbole mit A, die Starter mit B.
D=$(diff <(echo "$A_AUSGANG" | grep '  icons/') <(stand | grep '  icons/') | grep '^[<>]')
[ -z "$D" ] && ok "[B] zurueck: Symbole byte-gleich Ausgang 19.10." || { nok "[B] zurueck: Symbole weichen ab"; echo "$D" | head; }
[ "$(starter | grep -v 'org.querencia.Einstellungen.desktop$')" = "$(echo "$ST0" | grep -v 'org.querencia.Einstellungen.desktop$')" ] && ok "[B] zurueck: alle anderen Starter byte-gleich Live" || nok "[B] zurueck: andere Starter verändert"
d=$(diff ~/.local/share/applications/org.querencia.Einstellungen.desktop "$B/apps/org.querencia.Einstellungen.desktop" | grep '^[<>]')
[ "$(echo "$d" | wc -l)" = 2 ] && echo "$d" | grep -qx '> Icon=preferences-system' && ok "[B] zurueck: Einstellungen-Starter nur Icon= → preferences-system" || nok "[B] Einstellungen-Starter: mehr als Icon= geändert"
lauf 0 bash "$SKRIPT" aktivieren
lauf 0 bash "$SKRIPT" zurueck-0.4
D=$(diff <(echo "$LIVE") <(stand) | grep '^[<>]')
[ -z "$D" ] && ok "[B] aktivieren aus Ausgang + zurueck-0.4: byte-gleich Live-Stand" || { nok "[B] weicht vom Live-Stand ab"; echo "$D" | head; }
[ "$(grep -c . "$B/opt/protokoll.txt")" -ge 8 ] && ok "[B] Journal geschrieben ($(grep -c . "$B/opt/protokoll.txt") Zeilen)" || nok "[B] Journal fehlt"

echo "################ T: neuer Terminal-Starter (Simulation der App-ID-Session)"
FALL=T; baum T /dev/null ohne-tn; nutze T
sed -e 's/^StartupWMClass=.*/StartupWMClass=org.querencia.Terminal/' -e '/^# /d' -e '/^NoDisplay=/d' "$B/apps/$TB" >"$B/apps/$TN"
grep -qx 'NoDisplay=true' "$B/apps/$TB" || printf 'NoDisplay=true\n' >>"$B/apps/$TB"
desktop-file-validate "$B/apps/$TN" >/dev/null && desktop-file-validate "$B/apps/$TB" >/dev/null && ok "[T] simulierte Starter gültig" || nok "[T] simulierte Starter ungültig"
cp -p "$B/apps/$TN" "$W/t-tn.desktop"; cp -p "$B/apps/$TB" "$W/t-tb.desktop"
T0=$(stand)
[ "$(zust)" = "$(Z neu neu neu alt alt)" ] && ok "[T] TerminalStarter alt" || nok "[T] $(zust)"
fehler aktivieren "$T0" TerminalStarter signal-TerminalStarter TerminalBruecke
lauf 0 bash "$SKRIPT" aktivieren
[ "$(zust)" = "$(Z neu neu neu neu neu)" ] && ok "[T] nach aktivieren alles neu" || nok "[T] $(zust)"
nur_icon "$W/t-tn.desktop" "$B/apps/$TN" org.querencia.Terminal && nur_icon "$W/t-tb.desktop" "$B/apps/$TB" org.querencia.Terminal && ok "[T] beide Terminal-Starter: nur Icon=" || nok "[T] mehr als Icon= geändert"
grep -qx 'NoDisplay=true' "$B/apps/$TB" && grep -qx 'StartupWMClass=org.querencia.Terminal' "$B/apps/$TN" && ok "[T] NoDisplay und StartupWMClass der App-ID-Session erhalten" || nok "[T] Zeilen der App-ID-Session verloren"
T1=$(stand)
fehler zurueck-0.4 "$T1" TerminalStarter signal-TerminalBruecke ScreenshotStarter
lauf 0 bash "$SKRIPT" zurueck-0.4
[ "$(stand)" = "$T0" ] && ok "[T] zurueck-0.4: byte-gleich vor aktivieren" || { nok "[T] zurueck-0.4 weicht ab"; diff <(echo "$T0") <(stand) | head; }
echo "## Starter erst nach der Aktivierung von 0.4 angelegt (App-ID-Session aktiviert später)"
beiseite "$B/apps/$TN"; lauf 0 bash "$SKRIPT" aktivieren
cp -p "$W/t-tn.desktop" "$B/apps/$TN"
[ "$(zust)" = "$(Z neu neu neu alt neu)" ] && ok "[T] später angelegter Starter: alt, Rest neu" || nok "[T] $(zust)"
lauf 0 bash "$SKRIPT" aktivieren
[ "$(zust)" = "$(Z neu neu neu neu neu)" ] && ok "[T] erneutes aktivieren holt ihn nach" || nok "[T] $(zust)"

echo "################ F: fremde Stände"
FALL=F; baum F /dev/null ohne-tn; nutze F
cp -p "$B/icons/hicolor/scalable/apps/org.querencia.Terminal.svg" "$W/f-terminal.svg"
printf '<svg xmlns="http://www.w3.org/2000/svg"/>\n' >"$B/icons/hicolor/scalable/apps/org.querencia.Terminal.svg"; S0=$(stand)
[ "$(zust)" = "neu neu neu neu neu neu neu neu fremd neu neu fehlt alt alt" ] && ok "[F] Terminal-Symbol abweichend: fremd" || nok "[F] $(zust)"
lauf 2 bash "$SKRIPT" aktivieren; lauf 2 bash "$SKRIPT" zurueck-0.3; lauf 2 bash "$SKRIPT" zurueck-0.4; lauf 2 bash "$SKRIPT" zurueck
[ "$(stand)" = "$S0" ] && ok "[F] fremdes Terminal-Symbol: nichts geändert" || nok "[F] verändert"
cp -p "$W/f-terminal.svg" "$B/icons/hicolor/scalable/apps/org.querencia.Terminal.svg"
mkdir -p "$B/icons/hicolor/48x48/apps"; cp "$I/vorlage/icons/hicolor/64x64/apps/org.querencia.Files.png" "$B/icons/hicolor/48x48/apps/org.querencia.Files.png"; S0=$(stand)
lauf 2 bash "$SKRIPT" aktivieren
[ "$(stand)" = "$S0" ] && ok "[F] Files 48x48 vorhanden: verweigert, nichts geändert" || nok "[F] verändert"
beiseite "$B/icons/hicolor/48x48/apps/org.querencia.Files.png"
cp -p "$B/apps/$SS" "$W/f-ss.desktop"
sed -i 's/^Icon=.*/Icon=etwas-anderes/' "$B/apps/$SS"; S0=$(stand)
lauf 2 bash "$SKRIPT" aktivieren; lauf 2 bash "$SKRIPT" zurueck-0.4
[ "$(stand)" = "$S0" ] && ok "[F] Screenshot-Starter mit anderem Icon=: nichts geändert" || nok "[F] verändert"
cp -p "$W/f-ss.desktop" "$B/apps/$SS"; echo 'Icon=applets-screenshooter' >>"$B/apps/$SS"; S0=$(stand)
lauf 2 bash "$SKRIPT" aktivieren
[ "$(stand)" = "$S0" ] && ok "[F] zwei Icon=-Zeilen: nichts geändert" || nok "[F] verändert"
cp -p "$W/f-ss.desktop" "$B/apps/$SS"
ln -s "$B/apps/$TB" "$B/apps/$TN"; S0=$(stand)
[ "$(zust | cut -d' ' -f12)" = fremd ] && ok "[F] Terminal-Starter als Link: fremd" || nok "[F] Link: $(zust)"
lauf 2 bash "$SKRIPT" aktivieren
[ "$(stand)" = "$S0" ] && ok "[F] Terminal-Starter als Link: nichts geändert" || nok "[F] verändert"
beiseite "$B/apps/$TN"
sed -i 's/^Icon=.*/Icon=etwas-anderes/' "$B/apps/org.querencia.Einstellungen.desktop"; S0=$(stand)
lauf 2 bash "$SKRIPT" aktivieren; lauf 2 bash "$SKRIPT" zurueck-0.4
[ "$(stand)" = "$S0" ] && ok "[F] fremder Einstellungen-Starter: nichts geändert" || nok "[F] verändert"
unset SYM_OPT SYM_APPS SYM_ICONS SYM_STATE
echo "ERGEBNIS: $PASS PASS, $FAIL FAIL"
[ "$FAIL" = 0 ]
