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

## Aufbau

| Ordner | Inhalt |
|---|---|
| `quellen/` | SVG-Quellen (Quelle der Wahrheit); `entwurf/` verworfene Varianten |
| `integration/` | Integrationsskripte mit Vorlagen und `SHA256SUMS` |
| `werkzeug/` | Rendern, Thema bauen, Übersichten, Proben, isolierte Belegläufe |
| `nachweis/` | Probe-Logs, Belegbilder, Nachkontrollen |

## Benutzung

```bash
bash integration/symbole-integrieren.sh pruefen   # Programmsymbole und Starter-Icon=-Zeilen
bash integration/thema-integrieren.sh pruefen     # Symbolthema ~/.local/share/icons/Querencia
```

`aktivieren` und `zurueck` führt nur die Status-Session nach Freigabe aus
(`SYM_FREIGABE=ja` bzw. `THM_FREIGABE=ja`). Proben laufen gegen umgelenkte
Pfade: `werkzeug/symbole-probe-0.5.sh`, `werkzeug/thema-probe.sh`.

Nach einer Änderung an `quellen/thema/` baut `werkzeug/thema-vorlage-erzeugen.sh`
die Vorlage neu. `werkzeug/thema-uebersicht.py` zeichnet die Übersicht je Größe.

## Lizenz

Noch keine Lizenzdatei: Die Lizenz legt der Besitzer fest. Übernommene Bilder
(Laufwerke, Netzwerk, Lautstärke, Logo) stammen aus querencia-runtime, siehe
`quellen/thema/namen.txt`. Geschrieben mit KI-Unterstützung.
