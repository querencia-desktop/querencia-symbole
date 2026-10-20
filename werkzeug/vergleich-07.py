#!/usr/bin/env python3
"""Symbole 0.7: Vergleichsbilder für den Bericht aus zwei Belegläufen
(nachweis/symbole-07/belege/<ausgang>, <neu>): Ausschnitte nebeneinander
(links Stand 0.6, rechts 0.7), vergrößert ohne Glättung. Files-Seitenleiste
und Desktop nur, wenn der Lauf sie hat (szenario-07.sh ab dem Alias).
Aufruf: python3 -I vergleich-07.py <belege> <ausgang> <neu> <BxH> <ziel>"""
import os
import sys

import gi

gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf  # noqa: E402

RAND = 8
# Seitenleiste von Querencia Files (x, y, b, h) je Auflösung
FILES = {"1024x768": (0, 155, 205, 235), "1920x1080": (360, 270, 205, 235)}


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
    belege, ausgang, neu, res, ziel = sys.argv[1:6]
    h = int(res.split("x")[1])
    os.makedirs(ziel, exist_ok=True)
    a, n = os.path.join(belege, ausgang), os.path.join(belege, neu)
    knopf = [[ausschnitt(os.path.join(d, f"{p}-{res}.png"), 0, 0, 120, 32, 4) for d in (a, n)]
             for p in ("p01-knopf", "p02-knopf-mit-fenstern", "p04-knopf-gedrueckt")]
    nebeneinander(knopf, os.path.join(ziel, f"knopf-vorher-nachher-{res}.png"))
    orte = [[ausschnitt(os.path.join(d, f"o00-orte-{res}.png"), 160, 30, 180, 180, 2) for d in (a, n)]]
    nebeneinander(orte, os.path.join(ziel, f"orte-vorher-nachher-{res}.png"))
    zubehoer = [[ausschnitt(os.path.join(d, f"m10-kategorie-0-{res}.png"), 190, 30, 225, 230, 2) for d in (a, n)]]
    nebeneinander(zubehoer, os.path.join(ziel, f"zubehoer-vorher-nachher-{res}.png"))
    leiste = [[ausschnitt(os.path.join(d, f"p03-nach-klick-{res}.png"), 0, h - 32, 460, 32, 2)] for d in (a, n)]
    nebeneinander(leiste, os.path.join(ziel, f"leiste-nach-klick-vorher-nachher-{res}.png"))
    if os.path.exists(os.path.join(n, f"f00-files-{res}.png")):
        x, y, bb, hh = FILES[res]
        files = [[ausschnitt(os.path.join(d, f"f00-files-{res}.png"), x, y, bb, hh, 2) for d in (a, n)]]
        nebeneinander(files, os.path.join(ziel, f"files-vorher-nachher-{res}.png"))
        desktop = [[ausschnitt(os.path.join(d, f"d00-desktop-{res}.png"), 0, 32, 120, 380, 2) for d in (a, n)]]
        nebeneinander(desktop, os.path.join(ziel, f"desktop-vorher-nachher-{res}.png"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
