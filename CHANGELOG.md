# Änderungsprotokoll – Querencia Symbole

Format nach [Keep a Changelog](https://keepachangelog.com/de/1.1.0/). Die
Einträge sind aus den Tag-Texten und Commits zusammengefasst; ab 0.4 betreffen
die Fassungen vor allem das Einrichten in der Entwicklungsumgebung, die
Symbole selbst änderten sich mit 0.3, 0.6 und 0.7.

## [Unveröffentlicht]

### Geändert
- Werkzeuge ohne feste Heimpfade: `isoliert.py`, `beleg-lauf*.sh`,
  `beleg-profil*.sh` und `szenario-*.sh` nehmen `$HOME`,
  `XDG_CONFIG_HOME`/`XDG_DATA_HOME` oder Parameter (`LABWC_BIN`, `LABWC_VORGABE`,
  `PANEL`, `PDF`). Thema-Daten und Bau unverändert.

## [0.7] – 2026-10-21

### Hinzugefügt
- Thema Querencia: `user-desktop` neu als Arbeitsfläche mit Leiste und zwei
  minimierten Fenstern (Panel-Knopf „Arbeitsfläche anzeigen“, zugleich
  Ordner „Arbeitsfläche“, Entscheidung vom 21.10.2026: Variante A wie
  GNOME 2/Human), dazu `user-desktop-symbolic` und der Alias `show-desktop`
  (+ `-symbolic`) auf dasselbe Bild für einen späteren Runtime-Auftrag. Der
  Ordner-Entwurf bis 0.6 liegt unter `quellen/entwurf/user-desktop-ordner-0.6.svg`.
- `werkzeug/thema-bauen.py`: Namen auf `-symbolic` nur als SVG (GTK 4 färbt
  nur SVG um).
- Programmsymbole `org.querencia.{Archiv,Software,Dateisuche,Rechner,Kuerzel}`
  im Thema (byte-gleich aus den Programm-Repos, GPL-3.0-or-later,
  `quellen/thema/programme/HERKUNFT.txt`), 16–256 + SVG, ohne 48×48.
- Einrichtung `symbole-07-integrieren.sh` im Arbeitsordner
  `~/projects/querencia-symbole-07/` (Vorlage alt/neu, `zurueck-0.6`);
  live seit 21.10.2026 01:03:30.

## [0.6] – 2026-10-20

### Hinzugefügt
- Eigenes Symbol `org.querencia.Dokumente` (Blatt mit Lupe, neu gezeichnet;
  Entwurf aus Dokumente 0.1.0 unter `quellen/entwurf/`) im Thema Querencia und
  in hicolor; Einrichtung über die eigene Datei `symbole-integrieren-0.6.sh`
  mit eigener Vorlage.

## [0.5.2] – 2026-10-20

### Geändert
- Einrichtung `symbole-integrieren-0.5.2.sh`: Verbesserungen aus 0.5.1 als
  eigene Datei; die geprüfte 0.5-Datei bleibt unverändert liegen, weil
  Journalzeilen auf sie zeigen. Probe 193/0, Nachkontrolle PASS.

## [0.5.1] – 2026-10-20

### Behoben
- Rückrollen stellt Starter mit den Rechten der Sicherung her (vorher 0644
  statt 664).

## [0.5] – 2026-10-20

### Hinzugefügt
- Einrichtung als eigene Datei `symbole-integrieren-0.5.sh`: zusätzlich die
  `Icon=`-Zeile des Files-Starters (`folder` → `org.querencia.Files`).

## [0.4] – 2026-10-20

### Geändert
- Einrichtung setzt die `Icon=`-Zeilen der Terminal-Starter (auch der Brücke)
  und des Screenshot-Starters auf die eigenen Symbole.

## [0.3] – 2026-10-20

### Hinzugefügt
- Programmsymbole für Files (Aktenschrank), Terminal (Prompt) und Screenshot
  (Kamera) im Stil von 0.1.
- Symbolthema „Querencia“ mit 82 Namen, `Inherits=gnome-human,hicolor`.

## [0.2] – 2026-10-19

### Geändert
- Einrichtung ändert an Startern nur noch die `Icon=`-Zeile.

## [0.1] – 2026-10-19

Erste Fassung: eigene Programmsymbole für Systemmonitor,
Einstellungen, Editor, Bilder, Sitzung und Lautstärkeregler (PNG 16–256 und
SVG, ohne 48×48), Einrichtungsskript, Proben, Belege.
