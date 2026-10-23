#!/usr/bin/env python3
"""Symbole 0.8: Kontrast eines Symbols gegen helle und dunkle Flächen.
Je Größe und Grund: das PNG (bzw. das gerenderte SVG) über die Fläche legen
und für jedes deckende Pixel (Alpha ≥ 50 %) das Kontrastverhältnis nach
WCAG 2 zur Fläche rechnen. Ausgabe je Zeile: Anteil der Pixel mit ≥ 3:1
(sichtbare Umrisse und Flächen) und der größte Wert. Die Flächen sind die
Farben von Querencia-Klassisch (hell) und der dunklen Fassung 0.2.2
(Fenster #3c3b37, Menü #353430, Ansicht #2b2a27, aus der Thema-Übergabe).
Aufruf: python3 -I kontrast.py <svg> [<svg> …]"""
import sys

import gi

gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf  # noqa: E402

GROESSEN = (16, 22, 24, 32, 64)
FLAECHEN = (
    ("hell Fenster #edeceb", 0xED, 0xEC, 0xEB),
    ("hell Ansicht #ffffff", 0xFF, 0xFF, 0xFF),
    ("dunkel Fenster #3c3b37", 0x3C, 0x3B, 0x37),
    ("dunkel Menü #353430", 0x35, 0x34, 0x30),
    ("dunkel Ansicht #2b2a27", 0x2B, 0x2A, 0x27),
)


def leuchte(r, g, b):
    def k(c):
        c /= 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * k(r) + 0.7152 * k(g) + 0.0722 * k(b)


def verhaeltnis(a, b):
    hi, lo = max(a, b), min(a, b)
    return (hi + 0.05) / (lo + 0.05)


def messen(svg, n, grund):
    bild = GdkPixbuf.Pixbuf.new_from_file_at_scale(svg, n, n, True)
    daten = bild.get_pixels()
    zeile, kanaele = bild.get_rowstride(), bild.get_n_channels()
    lg = leuchte(*grund)
    werte = []
    for y in range(n):
        for x in range(n):
            i = y * zeile + x * kanaele
            r, g, b, a = daten[i], daten[i + 1], daten[i + 2], daten[i + 3]
            if a < 128:
                continue
            f = a / 255
            mix = [round(c * f + h * (1 - f)) for c, h in zip((r, g, b), grund)]
            werte.append(verhaeltnis(leuchte(*mix), lg))
    anteil = sum(1 for w in werte if w >= 3) / len(werte) if werte else 0
    return anteil, max(werte) if werte else 0


def main() -> int:
    print("Symbol | Fläche | " + " | ".join(f"{n} px" for n in GROESSEN))
    for svg in sys.argv[1:]:
        name = svg.rsplit("/", 1)[-1].removesuffix(".svg")
        for titel, *grund in FLAECHEN:
            felder = []
            for n in GROESSEN:
                anteil, hoechst = messen(svg, n, grund)
                felder.append(f"{anteil * 100:.0f} % (max {hoechst:.1f}:1)")
            print(f"{name} | {titel} | " + " | ".join(felder))
    return 0


if __name__ == "__main__":
    sys.exit(main())
