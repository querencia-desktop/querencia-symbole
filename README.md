# Querencia Symbole

Eigene Programmsymbole und das Symbolthema „Querencia“ von Querencia Desktop.
Die Symbole sind flach, haben graue Linien (#5a5a5a) und einen Akzent in
Querencia-Orange (#F07746). Sie folgen der GNOME-2-/Human-Optik und sind bei
16 und 22 px lesbar.

- **Programmsymbole** (`quellen/org.querencia.*.svg`): Systemmonitor,
  Einstellungen, Editor, Bilder, Sitzung, Lautstärkeregler (G2-V) sowie Files,
  Terminal und Screenshot (Thema-2). Sie werden in
  `~/.local/share/icons/hicolor` installiert, als PNG 16/22/24/32/64/128/256
  und als SVG, **nie 48×48** (GTK-4.22-Absturz bei 48×48 neben scalable).
- **Symbolthema „Querencia“** (`quellen/thema/`): 82 Namen für Ordner,
  Papierkorb, Computer, Laufwerke, Netzwerk, Lautstärke, Meldungen,
  Menükategorien und Panel-Einstellungen. `Inherits=gnome-human,hicolor`.
  `namen.txt` ordnet jedem Namen seine Quelle zu, `genutzt.txt` listet die
  Namen, die Panel und Desktop abfragen.

> **Alpha.** Noch nicht alle Programme haben ein eigenes Symbol im Repo
> (Dokumente folgt mit 0.6, Archiv als Entwurf im Archiv-Repo).

## Stand

| | |
|---|---|
| Version | 0.5.2 (Tag `symbole/0.5.2`) |
| Auf der Entwicklungs-VM | 0.5.2 live seit 20.10.2026; 0.6 (Symbol `org.querencia.Dokumente`, Tag `symbole/0.6`, Zweig `symbole-06`) geprüft und freigegeben, noch nicht aktiviert |
| Letzte Prüfung | 0.5.2: Probe 193/0 gegen umgelenkte Pfade, `pruefen` live, Nachkontrolle PASS |

Änderungen je Version: [CHANGELOG.md](CHANGELOG.md).

## Aufbau

| Ordner | Inhalt |
|---|---|
| `quellen/` | SVG-Quellen (Quelle der Wahrheit); `entwurf/` verworfene Varianten |
| `integration/` | Integrationsskripte mit Vorlagen und `SHA256SUMS` |
| `werkzeug/` | Rendern, Thema bauen, Übersichten, Proben, isolierte Belegläufe |
| `nachweis/` | Probe-Logs, Belegbilder, Nachkontrollen |

## Benutzung

```bash
bash integration/symbole-integrieren-0.5.2.sh pruefen # Fassung 0.5.2 (live seit 20.10.2026 11:01)
bash integration/thema-integrieren.sh pruefen     # Symbolthema ~/.local/share/icons/Querencia
```

`aktivieren` und `zurueck` führt nur die Status-Session nach Freigabe aus
(`SYM_FREIGABE=ja` bzw. `THM_FREIGABE=ja`). Proben laufen gegen umgelenkte
Pfade: `PROBE_SKRIPT=… werkzeug/symbole-probe-0.5.sh`, `werkzeug/thema-probe.sh`.
Die älteren Fassungen `symbole-integrieren.sh` (0.4) und `symbole-integrieren-0.5.sh`
(0.5) bleiben unverändert liegen, weil Journalzeilen auf sie zeigen.

Nach einer Änderung an `quellen/thema/` baut `werkzeug/thema-vorlage-erzeugen.sh`
die Vorlage neu. `werkzeug/thema-uebersicht.py` zeichnet die Übersicht je Größe.

## Bauen und Prüfen

`python3 -I werkzeug/rendern.py <quellordner> <ziel> <name> …` rendert die PNG-Stufen 16–256 (ohne 48), `werkzeug/thema-vorlage-erzeugen.sh` baut die Thema-Vorlage; Proben gegen umgelenkte Pfade mit `werkzeug/symbole-probe-0.5.sh` und `werkzeug/thema-probe.sh`.
Benutzung der Integrationsskripte siehe „Benutzung“; Belegbilder nur isoliert mit `werkzeug/beleg-lauf-thema2.sh` (headless labwc, eigener Bus, eigenes `HOME`).

## Lizenz

Symbole und Symbolthema (`quellen/` und alles daraus Gebaute):
CC-BY-SA-4.0, siehe [LICENSE](LICENSE); Namensnennung „Querencia Desktop
contributors“. Werkzeuge in `werkzeug/`: GPL-3.0-or-later, siehe
`werkzeug/LICENSE` (ENTSCHEIDUNGEN Nr. 19). Rechteinhaber, Vorbehalt für rein
KI-erzeugte Werke und Hinweise in [COPYRIGHT](COPYRIGHT). Übernommene Bilder
(Laufwerke, Netzwerk, Lautstärke, Logo) stammen aus querencia-runtime, siehe
`quellen/thema/namen.txt`. Name und Logo „Querencia“ sind keine freien
Inhalte (Markenregel).

