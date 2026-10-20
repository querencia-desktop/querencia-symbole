#!/usr/bin/env python3
"""Symbole 0.7: zeigt in der isolierten Sitzung ein Fenster mit dem
GTK-4-Dateiwähler (Seitenleiste mit Orten, dort user-desktop-symbolic) und
schließt es nach <sekunden>. Nur im Prüf-labwc aufrufen.
Aufruf: python3 -I dateiwahl-zeigen.py <sekunden>"""
import sys

import gi

gi.require_version("Gdk", "4.0")
gi.require_version("Gtk", "4.0")
from gi.repository import GLib, Gtk  # noqa: E402


def main() -> int:
    sekunden = int(sys.argv[1])
    app = Gtk.Application(application_id="org.querencia.Symbole07.Dateiwahl")

    def aktiv(app):
        fenster = Gtk.ApplicationWindow(application=app, title="Dateiwähler (Symbole 0.7)")
        fenster.set_default_size(760, 460)
        fenster.set_child(Gtk.FileChooserWidget(action=Gtk.FileChooserAction.OPEN))
        fenster.present()
        GLib.timeout_add_seconds(sekunden, app.quit)

    app.connect("activate", aktiv)
    return app.run([])


if __name__ == "__main__":
    sys.exit(main())
