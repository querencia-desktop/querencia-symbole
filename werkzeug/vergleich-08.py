#!/usr/bin/env python3
"""Symbole 0.8: Vergleichsbilder für den Bericht aus den Belegläufen
(nachweis/symbole-08/belege/<lauf>): Ausschnitte nebeneinander, links Stand
0.7 (ausgang-hell), dann 0.8 hell und 0.8 dunkel, vergrößert ohne Glättung.
Ausschnitte: Untermenü Zubehör, Starter auf der Arbeitsfläche, Fensterleiste,
linker Teil der Titelleiste (labwc setzt das 800×550-Fenster der Attrappe in
die Bildmitte).
Aufruf: python3 -I vergleich-08.py <belege> <BxH> <ziel>"""
import os
import sys

import gi

gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf  # noqa: E402

RAND = 8
LAEUFE = ("ausgang-hell", "neu-hell", "neu-dunkel")


def ausschnitt(datei, x, y, b, h, f):
    bild = GdkPixbuf.Pixbuf.new_from_file(datei).new_subpixbuf(x, y, b, h)
    return bild.scale_simple(b * f, h * f, GdkPixbuf.InterpType.NEAREST)


def nebeneinander(zeilen, ziel):
    breite = max(sum(b.get_width() for b in z) + RAND * (len(z) + 1) for z in zeilen)
    hoehe = sum(max(b.get_height() for b in z) for z in zeilen) + RAND * (len(zeilen) + 1)
    bogen = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, True, 8, breite, hoehe)
    bogen.fill(0x888888FF)
    y = RAND
    for z in zeilen:
        x = RAND
        for b in z:
            b.copy_area(0, 0, b.get_width(), b.get_height(), bogen, x, y)
            x += b.get_width() + RAND
        y += max(b.get_height() for b in z) + RAND
    bogen.savev(ziel, "png", [], [])


def main() -> int:
    belege, res, ziel = sys.argv[1:4]
    b, h = (int(v) for v in res.split("x"))
    kurz = res.split("x")[0]
    os.makedirs(ziel, exist_ok=True)
    laeufe = [os.path.join(belege, f"{lauf}-{kurz}") for lauf in LAEUFE]
    bild = lambda d, p: os.path.join(d, f"{p}-{res}.png")  # noqa: E731
    menue = [[ausschnitt(bild(d, "m10-kategorie-0"), 240, 30, 260, 275, 2) for d in laeufe]]
    nebeneinander(menue, os.path.join(ziel, f"zubehoer-{res}.png"))
    flaeche = [[ausschnitt(bild(d, "d00-arbeitsflaeche"), 0, 32, 140, h - 64, 1) for d in laeufe]]
    nebeneinander(flaeche, os.path.join(ziel, f"arbeitsflaeche-{res}.png"))
    leiste = [[ausschnitt(bild(d, "f01-fensterleiste"), 0, 0, 260, 32, 3)] for d in laeufe]
    nebeneinander(leiste, os.path.join(ziel, f"fensterleiste-{res}.png"))
    x, y = (b - 800) // 2, (h - 576) // 2
    titel = [[ausschnitt(bild(d, "f00-fenster"), x - 4, y - 4, 200, 36, 3)] for d in laeufe]
    nebeneinander(titel, os.path.join(ziel, f"titelleiste-{res}.png"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
