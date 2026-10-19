#!/usr/bin/env python3
"""G2-V: rendert aus quellen/<name>.svg die PNG-Stufen 16, 22, 24, 32, 64, 128, 256
(NIE 48x48, GTK-4.22-Symbolabsturz) nach <ziel>/icons/hicolor/<N>x<N>/apps/<name>.png
und kopiert das SVG nach <ziel>/icons/hicolor/scalable/apps/<name>.svg.
Offline über GdkPixbuf (SVG-Lader librsvg); rsvg-convert/Pillow fehlen auf der VM.
Aufruf: python3 -I rendern.py <quellordner> <ziel> <name> [<name> …]"""
import os
import shutil
import sys

import gi

gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf  # noqa: E402

STUFEN = (16, 22, 24, 32, 64, 128, 256)


def main() -> int:
    quelle, ziel, namen = sys.argv[1], sys.argv[2], sys.argv[3:]
    for name in namen:
        svg = os.path.join(quelle, name + ".svg")
        for n in STUFEN:
            assert n != 48
            ordner = os.path.join(ziel, "icons", "hicolor", f"{n}x{n}", "apps")
            os.makedirs(ordner, exist_ok=True)
            bild = GdkPixbuf.Pixbuf.new_from_file_at_scale(svg, n, n, True)
            if (bild.get_width(), bild.get_height()) != (n, n):
                print(f"{name} Stufe {n}: {bild.get_width()}x{bild.get_height()}", file=sys.stderr)
                return 1
            # tEXt-Felder leer lassen, damit die PNGs reproduzierbar sind
            bild.savev(os.path.join(ordner, name + ".png"), "png", [], [])
        ordner = os.path.join(ziel, "icons", "hicolor", "scalable", "apps")
        os.makedirs(ordner, exist_ok=True)
        shutil.copyfile(svg, os.path.join(ordner, name + ".svg"))
        print(name, "Stufen", " ".join(map(str, STUFEN)), "+ scalable")
    return 0


if __name__ == "__main__":
    sys.exit(main())
