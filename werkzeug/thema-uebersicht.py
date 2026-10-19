#!/usr/bin/env python3
"""Thema-2: Symbolübersicht des Themas „Querencia“ je Größe als PNG.

Schlägt jeden Namen aus quellen/thema/namen.txt und genutzt.txt so nach, wie
GTK es tut (Gtk.IconTheme mit Suchpfad <themenwurzel> und /usr/share/icons,
Thema „Querencia“), und zeichnet ihn pixelgenau in Originalgröße auf hellen
und dunklen Grund. Beschriftung: Name; geerbte Namen grau mit dem Thema, aus
dem sie kommen. Das Blatt entsteht als SVG mit eingebetteten PNGs und wird
mit GdkPixbuf (librsvg) gerendert; keine Anzeige nötig.
Aufruf: env -u WAYLAND_DISPLAY -u DISPLAY python3 -I thema-uebersicht.py
        <quellordner> <themenwurzel> <ausgabe-präfix> [<größe> …]"""
import base64
import os
import sys
from xml.sax.saxutils import escape

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf, Gtk  # noqa: E402

SPALTE, SPALTEN = 176, 7
HELL, DUNKEL = "#edeceb", "#3c3c3c"


def namen(datei, spalte):
    with open(datei, encoding="utf-8") as f:
        zeilen = [z.split() for z in f if z.strip() and not z.startswith("#")]
    return [z[spalte] for z in zeilen]


def nachschlagen(thema, wurzel, name, groesse):
    """(Pfad, Herkunftsthema) der Datei, die GTK für name/groesse nimmt."""
    info = thema.lookup_icon(name, None, groesse, 1, Gtk.TextDirection.LTR, 0)
    datei = info.get_file()
    pfad = datei.get_path() if datei else None
    if not pfad:
        return None, "fehlt"
    if pfad.startswith(os.path.join(wurzel, "Querencia") + os.sep):
        return pfad, "Querencia"
    teile = pfad.split(os.sep)
    return pfad, teile[teile.index("icons") + 1] if "icons" in teile else "?"


def bild_png(pfad, groesse):
    if pfad.endswith(".png"):
        bild = GdkPixbuf.Pixbuf.new_from_file(pfad)
        if bild.get_width() != groesse:
            bild = bild.scale_simple(groesse, groesse, GdkPixbuf.InterpType.BILINEAR)
    else:
        bild = GdkPixbuf.Pixbuf.new_from_file_at_scale(pfad, groesse, groesse, True)
    ok, daten = bild.save_to_bufferv("png", [], [])
    assert ok
    return base64.b64encode(daten).decode("ascii"), bild.get_width(), bild.get_height()


def blatt(thema, wurzel, eigene, geerbte, groesse, aus):
    alle = [(n, True) for n in eigene] + [(n, False) for n in geerbte]
    zeile = max(groesse, 16) + 34
    zeilen = (len(alle) + SPALTEN - 1) // SPALTEN
    breite, hoehe = SPALTE * SPALTEN * 2 + 24, zeilen * zeile + 40
    teile = [
        f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
        f'width="{breite}" height="{hoehe}" viewBox="0 0 {breite} {hoehe}">',
        f'<rect width="{breite}" height="{hoehe}" fill="#ffffff"/>',
        f'<rect x="8" y="30" width="{SPALTE * SPALTEN}" height="{hoehe - 34}" fill="{HELL}"/>',
        f'<rect x="{16 + SPALTE * SPALTEN}" y="30" width="{SPALTE * SPALTEN}" height="{hoehe - 34}" fill="{DUNKEL}"/>',
        f'<text x="8" y="20" font-family="DejaVu Sans" font-size="13" fill="#000000">'
        f"Symbolthema Querencia, {groesse} px – schwarz: eigenes Symbol, grau: geerbt (Thema in Klammern)</text>",
    ]
    fehlend = []
    for i, (name, eigen) in enumerate(alle):
        pfad, herkunft = nachschlagen(thema, wurzel, name, groesse)
        if eigen and herkunft != "Querencia":
            fehlend.append(name)
        for seite, grund in ((0, HELL), (1, DUNKEL)):
            x = 8 + seite * (SPALTE * SPALTEN + 8) + (i % SPALTEN) * SPALTE
            y = 36 + (i // SPALTEN) * zeile
            if pfad:
                daten, b, h = bild_png(pfad, groesse)
                teile.append(
                    f'<image x="{x + (SPALTE - b) // 2}" y="{y}" width="{b}" height="{h}" '
                    f'style="image-rendering:pixelated" xlink:href="data:image/png;base64,{daten}"/>'
                )
            text = name if eigen else f"{name} ({herkunft})"
            farbe = ("#000000" if eigen else "#7a7a7a") if grund == HELL else ("#ffffff" if eigen else "#a8a8a8")
            teile.append(
                f'<text x="{x + SPALTE // 2}" y="{y + max(groesse, 16) + 13}" text-anchor="middle" '
                f'font-family="DejaVu Sans" font-size="8" fill="{farbe}">{escape(text)}</text>'
            )
    teile.append("</svg>")
    svg = aus + ".svg"
    with open(svg, "w", encoding="utf-8") as f:
        f.write("\n".join(teile))
    GdkPixbuf.Pixbuf.new_from_file(svg).savev(aus + ".png", "png", [], [])
    os.remove(svg)
    return fehlend


def main() -> int:
    quelle, wurzel, praefix = sys.argv[1], os.path.abspath(sys.argv[2]), sys.argv[3]
    groessen = [int(g) for g in sys.argv[4:]] or [16, 22, 24, 32, 48, 64]
    eigene = namen(os.path.join(quelle, "thema", "namen.txt"), 1)
    geerbte = [n for n in namen(os.path.join(quelle, "thema", "genutzt.txt"), 0) if n not in eigene]
    thema = Gtk.IconTheme.new()
    thema.set_search_path([wurzel, "/usr/share/icons"])
    thema.set_theme_name("Querencia")
    fehler = 0
    for g in groessen:
        fehlend = blatt(thema, wurzel, eigene, geerbte, g, f"{praefix}-{g}")
        print(f"{praefix}-{g}.png: {len(eigene)} eigene, {len(geerbte)} geerbte Namen" + (f"; NICHT aus Querencia: {' '.join(fehlend)}" if fehlend else ""))
        fehler += len(fehlend)
    for n in geerbte:
        print("geerbt", n, nachschlagen(thema, wurzel, n, 22)[1])
    return 1 if fehler else 0


if __name__ == "__main__":
    sys.exit(main())
