#!/bin/bash
# Probe für thema-integrieren.sh gegen umgelenkte Pfade (Thema-2), immer mit
# allen drei Umlenkungen THM_OPT THM_ICONS THM_STATE:
#   Sperre  live ohne THM_FREIGABE, halbe Umlenkungen → verweigert
#   A  kein Thema → aktivieren (Fehlerstellen, Signale) → zurueck (dito)
#   G  GTK schlägt im Probebaum nach: eigene Namen aus Querencia, Rest geerbt
#   F  fremde Stände → verweigert, nichts geändert
# Live wird nur gelesen (hicolor-Kopie für den Probebaum).
# Aufruf: bash thema-probe.sh <leerer Arbeitsordner>
set -uo pipefail
R=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
SKRIPT=$R/integration/thema-integrieren.sh
VORLAGE=$R/integration/thema/vorlage/Querencia
W=${1:?Arbeitsordner}
mkdir -p "$W"
PASS=0; FAIL=0
ok()  { echo "PASS $*"; PASS=$((PASS+1)); }
nok() { echo "FAIL $*"; FAIL=$((FAIL+1)); }
baum() {
    local b=$W/$1; [ -e "$b" ] && { chmod -R u+w "$b"; rm -rf -- "${b:?}"; }
    mkdir -p "$b"/{opt/bin,icons,state}
    cp -a ~/.local/share/icons/hicolor "$b/icons/"
}
nutze() { export THM_OPT=$W/$1/opt THM_ICONS=$W/$1/icons THM_STATE=$W/$1/state; B=$W/$1; }
stand() { (cd "$B/icons" && find . -exec stat -c '%A %n' {} + | LC_ALL=C sort; find . -type f -exec sha256sum {} + | LC_ALL=C sort); }
zust() { bash "$SKRIPT" pruefen 2>&1 | sed -n 's/^thema-integrieren: Thema .*: \(alt\|neu\|fremd\)$/\1/p'; }
lauf() { local erw=$1; shift; out=$("$@" 2>&1); rc=$?; echo "$out" | sed 's/^/    /'; [ "$rc" = "$erw" ] && ok "[$FALL] ${*: -1} → Exit $rc" || nok "[$FALL] ${*: -1} → Exit $rc (erwartet $erw)"; }
fehler() { # befehl soll-stand stellen…
    local cmd=$1 soll=$2 f; shift 2
    for f in "$@"; do
        THM_PROBE=1 THM_FEHLER=$f lauf 1 bash "$SKRIPT" "$cmd"
        [ "$(stand)" = "$soll" ] && ok "[$FALL] Fehler $f bei $cmd: Baum byte-gleich" || { nok "[$FALL] Fehler $f bei $cmd: Baum verändert"; diff <(echo "$soll") <(stand) | head; }
    done
}

echo "################ Sperren"
FALL=Sperre
for cmd in aktivieren zurueck; do
    env -u THM_OPT -u THM_ICONS -u THM_STATE -u THM_FREIGABE bash "$SKRIPT" $cmd >/dev/null 2>&1; rc=$?
    [ $rc = 2 ] && ok "[Sperre] live $cmd ohne THM_FREIGABE → Exit 2" || nok "[Sperre] live $cmd ohne THM_FREIGABE → Exit $rc"
done
for teil in "THM_OPT" "THM_ICONS" "THM_OPT THM_ICONS" "THM_ICONS THM_STATE"; do
    setz=(); for v in $teil; do setz+=("$v=$W/halb/$v"); done
    env -u THM_OPT -u THM_ICONS -u THM_STATE "${setz[@]}" THM_FREIGABE=ja bash "$SKRIPT" aktivieren >/dev/null 2>&1; rc=$?
    [ $rc = 2 ] && ok "[Sperre] nur $teil umgelenkt → Exit 2" || nok "[Sperre] nur $teil umgelenkt → Exit $rc"
done
[ ! -e "$W/halb" ] && ok "[Sperre] halbe Umlenkung legte nichts an" || nok "[Sperre] halbe Umlenkung legte $W/halb an"
[ ! -e ~/.local/share/icons/Querencia ] && ok "[Sperre] live kein Querencia-Ordner" || nok "[Sperre] live Querencia vorhanden"

echo "################ A: kein Thema → aktivieren → zurueck"
FALL=A; baum A; nutze A
AUSGANG=$(stand)
[ "$(zust)" = alt ] && ok "[A] Ausgang alt" || nok "[A] Ausgang $(zust)"
fehler aktivieren "$AUSGANG" vor-kopie nach-kopie nach-umbenennen signal-vor-kopie signal-nach-kopie signal-nach-umbenennen
lauf 0 bash "$SKRIPT" aktivieren
[ "$(zust)" = neu ] && ok "[A] nach aktivieren neu" || nok "[A] nach aktivieren $(zust)"
diff -r "$VORLAGE" "$B/icons/Querencia" >/dev/null && ok "[A] Thema byte-gleich Vorlage" || nok "[A] Thema weicht ab"
[ -z "$(find "$B/icons/Querencia" -path '*48x48*' -print -quit)" ] && ok "[A] kein 48x48" || nok "[A] 48x48"
[ -z "$(find "$B/icons/Querencia" \( -type d ! -perm 0755 \) -o \( -type f ! -perm 0644 \) -print -quit)" ] && ok "[A] Rechte 0755/0644" || nok "[A] Rechte falsch"
diff <(echo "$AUSGANG" | grep -v Querencia) <(stand | grep -v Querencia) >/dev/null && ok "[A] außer Querencia/ nichts verändert (hicolor byte-gleich)" || nok "[A] anderes verändert"
[ -z "$(find "$B/icons" -maxdepth 1 -name '.Querencia*' -print -quit)" ] && ok "[A] keine Zwischenordner" || nok "[A] Zwischenordner übrig"
NEU=$(stand)
lauf 0 bash "$SKRIPT" aktivieren
[ "$(stand)" = "$NEU" ] && ok "[A] zweites aktivieren: nichts geändert" || nok "[A] zweites aktivieren änderte"
fehler zurueck "$NEU" vor-umbenennen nach-umbenennen nach-entfernen signal-vor-umbenennen signal-nach-umbenennen signal-nach-entfernen
lauf 0 bash "$SKRIPT" zurueck
[ "$(stand)" = "$AUSGANG" ] && ok "[A] zurueck: byte-gleich Ausgang" || { nok "[A] zurueck weicht ab"; diff <(echo "$AUSGANG") <(stand) | head; }
s=$(ls -d "$B"/state/sicherung-thema-zurueck-* 2>/dev/null | tail -1)
[ -n "$s" ] && diff -r "$VORLAGE" "$s/Querencia" >/dev/null && ok "[A] Sicherung enthält das entfernte Thema" || nok "[A] Sicherung fehlt"
lauf 0 bash "$SKRIPT" zurueck
[ "$(grep -c 'Thema-2' "$B/opt/protokoll.txt")" -ge 4 ] && ok "[A] Journal: $(grep -c 'Thema-2' "$B/opt/protokoll.txt") Zeilen" || nok "[A] Journal fehlt"

echo "################ G: GTK-Nachschlagen im Probebaum"
FALL=G; lauf 0 bash "$SKRIPT" aktivieren
G=$(env -u WAYLAND_DISPLAY -u DISPLAY python3 -I - "$B/icons" 2>&1 <<'EOF'
import sys, gi
gi.require_version("Gtk", "4.0")
from gi.repository import Gtk
wurzel = sys.argv[1]
t = Gtk.IconTheme.new(); t.set_search_path([wurzel, "/usr/share/icons"]); t.set_theme_name("Querencia")
def pfad(n, g):
    f = t.lookup_icon(n, None, g, 1, Gtk.TextDirection.LTR, 0).get_file()
    return f.get_path() if f else ""
fehler = 0
for n, g, erw in [("folder", 16, "/Querencia/16x16/places/folder.png"),
                  ("user-trash-full", 22, "/Querencia/22x22/status/user-trash-full.png"),
                  ("org.querencia.Terminal", 24, "/Querencia/24x24/apps/org.querencia.Terminal.png"),
                  ("computer", 48, "/Querencia/scalable/devices/computer.svg"),
                  ("applications-games", 16, "/Querencia/16x16/categories/applications-games.png"),
                  ("go-next", 22, "/gnome-human/"),
                  ("text-x-generic", 22, "/gnome/"),
                  ("org.querencia.Dateisuche", 32, "/hicolor/")]:
    p = pfad(n, g)
    gut = erw in p
    fehler += not gut
    print(("PASS" if gut else "FAIL") + f" [G] {n} {g} px → {p}")
sys.exit(1 if fehler else 0)
EOF
)
echo "$G" | grep -E '^(PASS|FAIL)'
PASS=$((PASS + $(echo "$G" | grep -c '^PASS'))); FAIL=$((FAIL + $(echo "$G" | grep -c '^FAIL')))
[ "$(echo "$G" | grep -c '^PASS')" = 8 ] || nok "[G] Nachschlagen unvollständig"
lauf 0 bash "$SKRIPT" zurueck

echo "################ F: fremde Stände"
FALL=F; baum F; nutze F
mkdir -p "$B/icons/Querencia"; echo x >"$B/icons/Querencia/index.theme"; S0=$(stand)
[ "$(zust)" = fremd ] && ok "[F] anderer Querencia-Ordner: fremd" || nok "[F] $(zust)"
lauf 2 bash "$SKRIPT" aktivieren; lauf 2 bash "$SKRIPT" zurueck
[ "$(stand)" = "$S0" ] && ok "[F] anderer Ordner: nichts geändert" || nok "[F] verändert"
rm -rf -- "$B/icons/Querencia"; cp -r "$VORLAGE" "$B/icons/Querencia"; chmod -R u+w "$B/icons/Querencia"; mkdir -p "$B/icons/Querencia/48x48/apps"; echo x >"$B/icons/Querencia/48x48/apps/folder.png"; S0=$(stand)
lauf 2 bash "$SKRIPT" zurueck
[ "$(stand)" = "$S0" ] && ok "[F] Vorlage + 48x48: fremd, nichts geändert" || nok "[F] verändert"
rm -rf -- "$B/icons/Querencia"; cp -r "$VORLAGE" "$B/icons/Querencia"; S0=$(stand)
[ "$(zust)" = fremd ] && ok "[F] schreibgeschützte Kopie der Vorlage: fremd" || nok "[F] schreibgeschützte Kopie: $(zust)"
lauf 2 bash "$SKRIPT" zurueck
[ "$(stand)" = "$S0" ] && ok "[F] schreibgeschützte Kopie: nichts geändert" || nok "[F] verändert"
chmod -R u+w "$B/icons/Querencia"; find "$B/icons/Querencia" -type f -exec chmod 0644 {} +; find "$B/icons/Querencia" -type d -exec chmod 0755 {} +
[ "$(zust)" = neu ] && ok "[F] dieselbe Kopie mit 0755/0644: neu" || nok "[F] mit 0755/0644: $(zust)"
rm -rf -- "$B/icons/Querencia"; ln -s "$VORLAGE" "$B/icons/Querencia"; S0=$(stand)
lauf 2 bash "$SKRIPT" zurueck
[ "$(stand)" = "$S0" ] && ok "[F] Link auf die Vorlage: fremd, nichts geändert" || nok "[F] verändert"
rm -f -- "$B/icons/Querencia"; mkdir "$B/icons/.Querencia.thm-neu"; S0=$(stand)
lauf 2 bash "$SKRIPT" aktivieren
[ "$(stand)" = "$S0" ] && ok "[F] Rest eines Laufs: verweigert, nichts geändert" || nok "[F] verändert"
unset THM_OPT THM_ICONS THM_STATE
echo "ERGEBNIS: $PASS PASS, $FAIL FAIL"
[ "$FAIL" = 0 ]
