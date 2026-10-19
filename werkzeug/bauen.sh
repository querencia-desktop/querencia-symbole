#!/bin/bash
# G2-V: Release-Builds von Editor und Systemmonitor aus den G2-V-Worktrees
# (~/projects/querencia-symbole-wt/{editor,systemmonitor}, Zweig g2v/symbol),
# hinter dem gemeinsamen Build-Lock, eigene Zielordner.
#   bauen.sh basis   nur cargo build --release (Nachbau-Probe gegen die Live-SHA256)
#   bauen.sh symbol  fmt + clippy + test + build --release (Stand mit neuem Fenstersymbol)
# Editor wie G2-E (Ubuntu cargo, CARGO_HOME der W5-Paketierung), Systemmonitor wie G2-S (~/.cargo).
set -uo pipefail
ART=${1:?basis|symbol}
WT=~/projects/querencia-symbole-wt
L=~/projects/querencia-symbole/nachweis/bau; mkdir -p "$L"
LOCK=~/.local/state/querencia/bau.lock
export CARGO_BUILD_JOBS=2 PATH=/usr/bin:/bin
bau() { # name quelle target cargo_home
    local name=$1 src=$2 tgt=$3 log=$L/$ART-$1.log
    : >"$log"; echo "== $name ($ART) $(git -C "$src" log -1 --format='%h %s'): warte auf Build-Lock $(date +%T)" | tee -a "$log"
    ( cd "$src" && export CARGO_TARGET_DIR=$tgt CARGO_HOME=$4 ART &&
      flock $LOCK bash -c '
        set -x
        if [ "$ART" = symbol ]; then
          /usr/bin/cargo fmt --all --check &&
          env -u WAYLAND_DISPLAY -u DISPLAY DBUS_SESSION_BUS_ADDRESS=disabled: nice -n 10 /usr/bin/cargo-clippy clippy --release --all-targets --offline --locked -- -D warnings &&
          env -u WAYLAND_DISPLAY -u DISPLAY DBUS_SESSION_BUS_ADDRESS=disabled: nice -n 10 /usr/bin/cargo test --release --offline --locked || exit 1
        fi
        env -u WAYLAND_DISPLAY -u DISPLAY nice -n 10 /usr/bin/cargo build --release --offline --locked
      ' ) >>"$log" 2>&1
    local rc=$?
    echo "== $name: fertig rc=$rc $(date +%T)" | tee -a "$log"
    return $rc
}
df -h / | tail -1 | tee "$L/$ART-df-vorher.txt"
bau editor $WT/editor $WT/target-editor ~/projects/querencia-werkstatt-w5-release/pakete/cargo-home; RE=$?
bau systemmonitor $WT/systemmonitor $WT/target-systemmonitor ~/.cargo; RS=$?
df -h / | tail -1 | tee "$L/$ART-df-nachher.txt"
sha256sum $WT/target-editor/release/querencia-editor $WT/target-systemmonitor/release/querencia-systemmonitor | tee "$L/$ART-sha256.txt"
echo "ERGEBNIS $ART editor=$RE systemmonitor=$RS" | tee -a "$L/$ART-sha256.txt"
