#!/usr/bin/env python3
"""Symbole 0.7: fragt im laufenden (isolierten) GTK 4 das Symbolthema nach
Namen und Größen und schreibt je Zeile die Datei, die GTK lädt.
Nur in der isolierten Sitzung aufrufen (WAYLAND_DISPLAY des Prüf-labwc).
Aufruf: python3 -I symbol-nachschlagen.py <größe>[,<größe>…] <name> [<name> …]"""
import sys

import gi

gi.require_version("Gdk", "4.0")
gi.require_version("Gtk", "4.0")
from gi.repository import Gdk, Gtk  # noqa: E402


def main() -> int:
    groessen = [int(g) for g in sys.argv[1].split(",")]
    Gtk.init()
    anzeige = Gdk.Display.get_default()
    thema = Gtk.IconTheme.get_for_display(anzeige)
    print(f"Thema: {Gtk.Settings.get_default().props.gtk_icon_theme_name}; Suchpfade: {' '.join(thema.get_search_path())}")
    for name in sys.argv[2:]:
        for n in groessen:
            bild = thema.lookup_icon(name, None, n, 1, Gtk.TextDirection.NONE, 0)
            datei = bild.get_file()
            print(f"{name} {n}: {datei.get_path() if datei else bild.get_icon_name()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
