# Querencia Symbole

Eigene Programmsymbole und das Symbolthema „Querencia“ für alle, die
Querencia Desktop benutzen. Teil von
[Querencia Desktop](https://querencialinux.org) – einer
klassischen Desktopumgebung im GNOME-2-Stil für Wayland (labwc, Rust, GTK 4).
Installiert wird es zusammen mit Querencia Desktop aus der APT-Quelle;
Anleitung auf <https://querencialinux.org>.

*English summary:* Application icons and the “Querencia” icon theme of
Querencia Desktop: flat, grey line art with an orange accent in the spirit of
GNOME 2's Human icons, built from SVG sources. Part of Querencia Desktop, a
classic GNOME-2-style desktop for Wayland. Alpha; documentation is in German.

> **Alpha.** Das Thema deckt 92 Namen ab; alles andere erbt es von
> `gnome-human`, dann `hicolor`. Keine Gewähr für Vollständigkeit.

## Zweck

- **Programmsymbole** (`quellen/org.querencia.*.svg`): Systemmonitor,
  Einstellungen, Editor, Bilder, Sitzung, Lautstärkeregler, Files, Terminal,
  Screenshot, Dokumente (Blatt mit Lupe, seit 0.6) und Dateien (Fenster mit
  Seitenleiste und Ordner, seit 0.8). Installiert werden sie als PNG 16/22/24/32/64/128/256 und
  als SVG, **nie 48×48** (GTK 4.22 stürzt ab, wenn ein Symbol in 48×48 und als
  Scalable vorliegt).
- **Symbolthema „Querencia“** (`quellen/thema/`): 92 Namen für Ordner,
  Papierkorb, Computer, Laufwerke, Netzwerk, Lautstärke, Meldungen,
  Menükategorien und Panel-Einstellungen; seit 0.7 `user-desktop` (Panel-Knopf
  „Arbeitsfläche anzeigen“ und Ordner „Arbeitsfläche“, dazu
  `user-desktop-symbolic` und der Alias `show-desktop`; symbolische Namen nur
  als SVG) und die Programmsymbole Archiv, Software, Dateisuche, Rechner und
  Kürzel aus ihren Repos (`quellen/thema/programme/`, GPL-3.0-or-later);
  `Inherits=gnome-human,hicolor`.
  `namen.txt` ordnet jedem Namen seine Quelle zu, `genutzt.txt` listet die
  Namen, die Panel und Desktop abfragen.
- Gestaltung: flach, graue Linien (`#5a5a5a`), Akzent in Querencia-Orange
  (`#F07746`), bei 16 und 22 px lesbar.
- Bewusst **nicht** Teil dieses Repos: ein vollständiges Symbolthema (das
  Grundthema bleibt `gnome-human`), Mauszeiger, GTK-Thema.

| Ordner | Inhalt |
|---|---|
| `quellen/` | SVG-Quellen (Quelle der Wahrheit); `entwurf/` verworfene Varianten; `thema/uebernommen/` byte-gleiche Kopien aus dem Repo `querencia-shell` (Laufwerke, Netzwerk, Lautstärke, Logo) |
| `werkzeug/` | Rendern (`rendern.py`), Thema bauen (`thema-bauen.py`), Übersichten und isolierte Belegläufe; Pfade aus `$HOME`, `XDG_CONFIG_HOME`/`XDG_DATA_HOME` oder Parametern (`LABWC_BIN`, `LABWC_VORGABE`, `PANEL`, `PDF`, `EDITOR_BIN`, `SYSMON_BIN`) |

## Stand

| | |
|---|---|
| Version | 0.8 (Tags `symbole/0.8`, `symbole/0.8-int`; Programmsymbol Dateien im Thema); davor 0.7 (Symbol für „Arbeitsfläche anzeigen“, Programmsymbole Archiv, Software, Dateisuche, Rechner, Kürzel im Thema) |
| Letzte Prüfung | 23.10.2026: `werkzeug/thema-bauen.py` baut aus `quellen/` reproduzierbar 723 Dateien (92 Namen), zweimal gebaut gleich; gegenüber Stand 0.7 genau 8 Dateien mehr (`org.querencia.Dateien`), ohne 48×48 |
| Bekannte Lücken | Die Belegläufe erwarten die Programme von Querencia Desktop unter `~/opt/querencia` (anders über die Parameter oben) |
| Getestet auf | Ubuntu 26.04, labwc 0.9.8, GTK 4.22 (librsvg über GdkPixbuf) |
| Nicht getestet | andere Symbolthemen als Grundlage, HiDPI |

## Bauen

Voraussetzungen (Ubuntu 26.04): `python3`, `python3-gi`,
`gir1.2-gdkpixbuf-2.0`, `librsvg2-common` (SVG-Lader).

```bash
python3 -I werkzeug/thema-bauen.py quellen <ziel>          # Symbolthema <ziel>/Querencia
python3 -I werkzeug/rendern.py quellen <ziel> org.querencia.Editor   # PNG-Stufen und SVG eines Programmsymbols
```

Reproduzierbar: zweimal in getrennte Ordner bauen und vergleichen
(`diff -r <ziel1> <ziel2>` ist leer).

## Prüfen

Keine CI (reines Daten-Repo). Prüfen heißt: Thema zweimal bauen und
vergleichen (siehe „Bauen“), keine 48×48-Stufe,
Sichtprüfung mit `werkzeug/thema-uebersicht.py`; die isolierten Belegläufe
(`werkzeug/beleg-lauf*.sh`) laufen nur in einer abgeschotteten Sitzung, nie in
der laufenden Desktopsitzung. Arbeitsweise: [CONTRIBUTING.md](CONTRIBUTING.md).

## Vorbild und Abgrenzung

Vorbild für die Gestaltung sind **die Human-Symbole von Ubuntu 10.04 und
GNOME 2.30**. Querencia übernimmt davon Stil und Farbstimmung, **keine
Grafiken**: alle Symbole sind eigene Zeichnungen. Das Projekt ist mit
Canonical, GNOME und deren Autoren weder verbunden noch von ihnen
unterstützt. Das Thema erbt fehlende Namen zur Laufzeit von `gnome-human`
(nicht mitgeliefert, Ubuntu-Paket `gnome-human-icon-theme`).

## Lizenz

Symbole und Symbolthema: CC-BY-SA-4.0, siehe [LICENSE](LICENSE); Werkzeuge in
`werkzeug/`: GPL-3.0-or-later, siehe [werkzeug/LICENSE](werkzeug/LICENSE).
Ausnahme: die Programmsymbole unter `quellen/thema/programme/` (Archiv,
Software, Dateisuche, Rechner, Kürzel) stehen wie ihre Programme unter
GPL-3.0-or-later; Herkunft in `quellen/thema/programme/HERKUNFT.txt`.
Copyright 2026 Querencia Desktop contributors; Urheberhinweis in
[COPYRIGHT](COPYRIGHT).

Name und Logo „Querencia“ (auch `quellen/thema/uebernommen/querencia-logo.svg`)
sind keine freien Inhalte: [MARKE.md](MARKE.md).

## Fehler melden

Fehler, Wünsche und Fragen zu Querencia gehen an die gemeinsame Meldestelle:
<https://github.com/querencia-desktop/querencia/issues/new/choose>.
Sicherheitslücken bitte nicht öffentlich melden, siehe [SECURITY.md](SECURITY.md).
