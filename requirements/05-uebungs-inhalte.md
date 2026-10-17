# 05 — Übungs-Inhalte

## Datenmodell

Eine Übung (exercise) besteht aus:

| Feld | Typ | Pflicht | Beschreibung |
|------|----|---------|---------------|
| title | String | ja | Übungsname, ≤ 30 Zeichen |
| caption | String | ja | Anleitung, 1–2 Sätze, ≤ 120 Zeichen |
| gifs | [String] | ja | 1–3 Dateinamen im Exercises-Ordner, Abspielreihenfolge = Array-Reihenfolge |

Katalog-Header (exercises.json):

| Feld | Typ | Default | Beschreibung |
|------|----|---------|--------------|
| perGifSeconds | Double | 6 | Sekunden pro GIF in der Sequenz |
| exercises | [Exercise] | — | der Übungs-Katalog |

## GIF-Spezifikation

| Eigenschaft | Anforderung | Begründung |
|-------------|-------------|------------|
| Format | GIF89a, animiert | breite Kompatibilität, kein Codec nötig |
| Auflösung | 400–480 px Höhe | scharf im 300-pt-Panel bei 2x |
| Dateigröße | ≤ 2 MB | Overlay soll sofort erscheinen, kein Flash beim Nachladen |
| Loop-Dauer | 4–8 s pro GIF | Wiederholung erkennbar, wirkt nicht hektisch |
| Framedauer | 60–100 ms/frame | flüssig, ohne CPU-Spitzen |
| Hintergrund | transparent bevorzugt | harmoniert mit hudWindow-Material |
| Ein Übungs-GIF zeigt | die Bewegungsausführung, Frontal- oder Seitenansicht | Nachvollziehbarkeit ohne Ton |

## Content-Richtlinien

1. **Ton:** freundlich, imperativ kurz („Kopf langsam zum Ohr neigen").
2. **Sicherheit:** keine Übungen mit Verletzungsrisiko ohne Warnhinweis;
   Belastungshinweise in der caption („Nicht in den Schmerz ziehen").
3. **Sprache:** Deutsch im MVP; alle Texte über String-Kataloge für spätere
   Lokalisierung.
4. **Inhaltliche Kuratierung:** Übungsset initial mit Fokus Nacken, Schulter,
   Brust, Handgelenke (klassische Bildschirmarbeits-Beschwerdebilder).
5. Zielbild: einmal validiertes Set von 10–15 Übungen, ggf. in Absprache mit
   Physiotherapeut:innen.

## Lizenzierung / Quellen

- Nur selbsterstellte GIFs oder eindeutig lizenzierte Inhalte (CC0/CC-BY mit
  Quellenangabe in einer CREDITS.md im Exercises-Ordner).
- Keine „ge-sourcten" Giphy/Tenor-GIFs ohne geklärte Nutzungslizenz.
- Übungs-GIFs werden nicht in git committet (.gitignore-Eintrag);
  ausgeliefert wird eine Beispiel-exercises.json mit Dateinamen-Platzhaltern.

## Beispieldatensatz (MVP)

| Übung | GIFs | Fokus |
|-------|------|-------|
| Nacken-Dehnung | neck-tilt-left, neck-tilt-right | laterale Halsmuskulatur |
| Schulterkreisen | shoulder-rolls | Schultergürtel-Mobilität |
| Brustdehnung | chest-stretch | verkürzte Brustmuskulatur |
