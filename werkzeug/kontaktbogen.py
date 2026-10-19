#!/usr/bin/env python3
"""G2-V: Kontaktbogen. Je Zeile ein Symbol in 16, 22, 24, 32, 64 px auf hellem und
dunklem Grund, dazu 16 und 22 px vierfach vergrößert (nächster Nachbar).
Aufruf: python3 -I kontaktbogen.py <ausgabe.png> <svg> [<svg> …]"""
import sys

import gi

gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf  # noqa: E402

GROESSEN = (16, 22, 24, 32, 64)
ZEILE = 100
HELL, DUNKEL = 0xEDECEBFF, 0x3C3C3CFF


def main() -> int:
    aus, svgs = sys.argv[1], sys.argv[2:]
    breite = 2 * (sum(GROESSEN) + 12 * len(GROESSEN)) + 16 * 4 + 22 * 4 + 60
    bogen = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, True, 8, breite, ZEILE * len(svgs))
    bogen.fill(0xFFFFFFFF)
    for z, svg in enumerate(svgs):
        y0 = z * ZEILE
        x = 0
        for grund in (HELL, DUNKEL):
            feld = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, True, 8, sum(GROESSEN) + 12 * len(GROESSEN), ZEILE - 4)
            feld.fill(grund)
            feld.copy_area(0, 0, feld.get_width(), feld.get_height(), bogen, x, y0 + 2)
            for n in GROESSEN:
                b = GdkPixbuf.Pixbuf.new_from_file_at_scale(svg, n, n, True)
                b.composite(bogen, x + 6, y0 + (ZEILE - n) // 2, n, n, x + 6, y0 + (ZEILE - n) // 2, 1, 1, GdkPixbuf.InterpType.NEAREST, 255)
                x += n + 12
            x += 10
        for n in (16, 22):
            b = GdkPixbuf.Pixbuf.new_from_file_at_scale(svg, n, n, True)
            g = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, True, 8, n * 4, n * 4)
            g.fill(HELL)
            b.composite(g, 0, 0, n * 4, n * 4, 0, 0, 4, 4, GdkPixbuf.InterpType.NEAREST, 255)
            g.copy_area(0, 0, n * 4, n * 4, bogen, x, y0 + (ZEILE - n * 4) // 2)
            x += n * 4 + 10
    bogen.savev(aus, "png", [], [])
    return 0


if __name__ == "__main__":
    sys.exit(main())
