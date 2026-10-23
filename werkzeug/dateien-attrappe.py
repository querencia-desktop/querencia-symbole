#!/usr/bin/env python3
"""Symbole 0.8: Attrappe für die Symbolbelege von Querencia Dateien. Ein leeres
GTK-4-Fenster mit der App-ID org.querencia.Dateien und dem Titel „Dokumente“
(Fenstertitel = Ordnername wie in Nautilus 2.30), ohne eigenes Fenstersymbol:
Fensterleiste und Titelleiste finden das Symbol über den Starter der App-ID.
Das Programm selbst entsteht getrennt (Welle B); die Attrappe zeigt nur, wie
das Symbol dort erscheint. Schließt sich nach <sekunden>.
Nur im Prüf-labwc aufrufen (WAYLAND_DISPLAY der isolierten Sitzung).
Aufruf: python3 -I dateien-attrappe.py <sekunden>"""
import sys

import gi

gi.require_version("Gtk", "4.0")
from gi.repository import GLib, Gio, Gtk  # noqa: E402


def main() -> int:
    sekunden = int(sys.argv[1])
    app = Gtk.Application(application_id="org.querencia.Dateien", flags=Gio.ApplicationFlags.NON_UNIQUE)

    def aktiv(app):
        fenster = Gtk.ApplicationWindow(application=app, title="Dokumente")
        fenster.set_default_size(800, 550)
        text = Gtk.Label(label="Attrappe für die Symbolbelege (org.querencia.Dateien)")
        fenster.set_child(text)
        fenster.present()
        GLib.timeout_add_seconds(sekunden, app.quit)

    app.connect("activate", aktiv)
    return app.run([sys.argv[0]])


if __name__ == "__main__":
    sys.exit(main())
