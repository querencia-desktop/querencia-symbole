#!/usr/bin/env python3
"""Thema-2: baut das Symbolthema „Querencia“ aus quellen/thema/namen.txt.

Je Name: PNG-Stufen 16, 22, 24, 32, 64, 128, 256 (NIE 48x48, GTK-4.22-
Symbolabsturz) nach <ziel>/Querencia/<N>x<N>/<kontext>/<name>.png und das SVG
nach <ziel>/Querencia/scalable/<kontext>/<name>.svg, dazu index.theme
(Inherits=gnome-human,hicolor). Offline über GdkPixbuf wie werkzeug/rendern.py;
PNGs ohne tEXt-Felder, damit der Bau reproduzierbar ist.
Aufruf: python3 -I thema-bauen.py <quellordner> <ziel>"""
import os
import shutil
import sys

import gi

gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf  # noqa: E402

STUFEN = (16, 22, 24, 32, 64, 128, 256)
KONTEXTE = {
    "apps": "Applications",
    "categories": "Categories",
    "devices": "Devices",
    "places": "Places",
    "status": "Status",
}
KOPF = """[Icon Theme]
Name=Querencia
Comment=Symbolthema von Querencia Desktop: GNOME-2-Optik, flächig, Akzent #F07746
Inherits=gnome-human,hicolor
Example=folder
"""


def namen_lesen(datei):
    eintraege = []
    with open(datei, encoding="utf-8") as f:
        for nr, zeile in enumerate(f, 1):
            zeile = zeile.strip()
            if not zeile or zeile.startswith("#"):
                continue
            teile = zeile.split()
            if len(teile) != 3 or teile[0] not in KONTEXTE:
                raise SystemExit(f"{datei}:{nr}: unlesbar: {zeile}")
            eintraege.append(tuple(teile))
    namen = [n for _, n, _ in eintraege]
    doppelt = sorted({n for n in namen if namen.count(n) > 1})
    if doppelt:
        raise SystemExit(f"{datei}: doppelte Namen: {' '.join(doppelt)}")
    return eintraege


def index_theme(kontexte):
    ordner, abschnitte = [], []
    for n in STUFEN:
        for k in kontexte:
            ordner.append(f"{n}x{n}/{k}")
            abschnitte.append(f"[{n}x{n}/{k}]\nSize={n}\nContext={KONTEXTE[k]}\nType=Fixed\n")
    for k in kontexte:
        ordner.append(f"scalable/{k}")
        abschnitte.append(
            f"[scalable/{k}]\nSize=64\nMinSize=8\nMaxSize=512\nContext={KONTEXTE[k]}\nType=Scalable\n"
        )
    return KOPF + "Directories=" + ",".join(ordner) + "\n\n" + "\n".join(abschnitte)


def main() -> int:
    quelle, ziel = sys.argv[1], sys.argv[2]
    eintraege = namen_lesen(os.path.join(quelle, "thema", "namen.txt"))
    thema = os.path.join(ziel, "Querencia")
    if os.path.exists(thema):
        print(f"{thema} gibt es schon – bitte leeres Ziel angeben", file=sys.stderr)
        return 1
    kontexte = sorted({k for k, _, _ in eintraege})
    for kontext, name, rel in eintraege:
        svg = os.path.join(quelle, rel)
        for n in STUFEN:
            assert n != 48
            ordner = os.path.join(thema, f"{n}x{n}", kontext)
            os.makedirs(ordner, exist_ok=True)
            bild = GdkPixbuf.Pixbuf.new_from_file_at_scale(svg, n, n, True)
            if (bild.get_width(), bild.get_height()) != (n, n):
                print(f"{name} Stufe {n}: {bild.get_width()}x{bild.get_height()}", file=sys.stderr)
                return 1
            bild.savev(os.path.join(ordner, name + ".png"), "png", [], [])
        ordner = os.path.join(thema, "scalable", kontext)
        os.makedirs(ordner, exist_ok=True)
        shutil.copyfile(svg, os.path.join(ordner, name + ".svg"))
    with open(os.path.join(thema, "index.theme"), "w", encoding="utf-8") as f:
        f.write(index_theme(kontexte))
    print(f"Querencia: {len(eintraege)} Namen, Stufen {' '.join(map(str, STUFEN))} + scalable, Kontexte {' '.join(kontexte)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
