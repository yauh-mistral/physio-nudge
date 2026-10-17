# 06 — Konfiguration und Daten

## Übungsdaten: Speicherorte (Suchreihenfolge)

1. ```~/Library/Application Support/PhysioNudge/Exercises/``` —
   **Nutzer-Katalog (hat Vorrang)**: eigene Übungen ohne Re-Build.
2. ```Contents/Resources/Exercises/``` im App-Bundle — mitgelieferter
   Default-Katalog.

Der erste Ort mit vorhandener exercises.json gewinnt. GIF-Dateinamen werden
relativ zum gewählten Ordner aufgelöst.

## exercises.json (Schema)

```json
{
  "perGifSeconds": 6,
  "exercises": [
    {
      "title": "Nacken-Dehnung",
      "caption": "Kopf langsam zum Ohr neigen, 15 Sekunden pro Seite.",
      "gifs": ["neck-tilt-left.gif", "neck-tilt-right.gif"]
    }
  ]
}
```

Validierungsregeln:
- JSON muss dekodierbar sein; sonst greift der Text-Fallback (FR-11).
- Übungen mit nicht existierenden GIF-Dateien werden gefiltert (FR-10).
- gifs darf nicht leer sein; leere Arrays → Übung wird übersprungen.

## App-Einstellungen

MVP: In-Memory + Menü-Auswahl (kein Persistenz-Zwang). Ab FR-12 (Should)
UserDefaults mit folgendem Schema:

| Key | Typ | Default | Beschreibung |
|-----|-----|---------|--------------|
| intervalMinutes | Int | 60 | Overlay-Intervall |
| corner | String | "bottomRight" | Overlay-Ecke |
| paused | Bool | false | Pausiert-Zustand |
| perGifSecondsOverride | Double? | nil | Überschreibt Katalog-Wert |

## Datenschutz

Alle Daten liegen lokal (Katalog, GIFs, Settings). Kein Netzwerkzugriff,
keine Telemetrie, kein Analytics — zugesagt für alle Releases.
