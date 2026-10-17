# 04 — Overlay-UX-Spec (Das Herzstück)

## Grundprinzip

Das Overlay ist ein **non-activating Corner-Overlay**: Es erscheint, ohne dass
irgendein Fenster den Fokus verliert, bleibt über allen Desktops und sogar
über Fullscreen-Apps sichtbar, und verschwindet nach der Übung von selbst.

## Visuelle Spezifikation

| Eigenschaft | Wert |
|-------------|------|
| Größe | 300 × 300 pt |
| Position | wählbare Ecke, 24 pt Abstand zu sichtbarem Screenbereich (Dock beachten) |
| Hintergrund | NSVisualEffectView, Material hudWindow, abgerundet (Radius 16) |
| Titel | Systemfont 14 pt semibold, weiß |
| Anleitungstext | Systemfont 12 pt, hellgrau, zentriert, max. Breite 260 pt |
| GIF-Bereich | proportional skaliert, oben im Stack |
| Schatten | aktiviert (deckt Overlay vom Inhalt ab) |

Skizze:

```
┌─────────────────────────┐
│                         │
│      [GIF-Animation]    │
│                         │
│      Nacken-Dehnung      │
│  Kopf langsam zum Ohr   │
│   neigen, 15 Sek. je    │
│         Seite.          │
└─────────────────────────┘
```

## Zeitverhalten

| Phase | Verhalten |
|-------|-----------|
| Einblenden | Fade-in über 350 ms (alphaValue 0 → 1), ohne Aktivierung |
| Pro GIF | Default 6 s (konfigurierbar: perGifSeconds) |
| Zwischen GIFs | harter Wechsel, GIF läuft als Loop während seiner Zeit |
| Ausblenden | Fade-out über 300 ms, Panel wird danach ganz entfernt |

## Interaktion

- **MVP:** keine Interaktion — das Overlay ist klick-transparent zu betrachten,
  schließt automatisch. (Kein „Weiter"-Button, kein Draggen.)
- **FR-13 (Should):** Klick auf das Overlay schließt es vorzeitig.
- Das Overlay wird **nie** key oder main: Tastatur/Klick-Fokus der laufenden
  App bleibt unangetastet (Kern-Akzeptanzkriterium).

## Sichtbarkeitsregeln

1. Auf **allen Spaces** sichtbar (canJoinAllSpaces).
2. Auch **über Fullscreen-Apps** (fullScreenAuxiliary) — z. B. Video im
   Vollbild: der Nudge bleibt sichtbar.
3. **Nicht anzeigen**, wenn: App pausiert (FR-05), Bildschirm gesperrt,
   Screensaver aktiv, oder (Should, FR-14) Meeting/Screen-Share läuft.
4. Nie zwei Overlays gleichzeitig (Guard im Controller).

## Nicht-Stören-Philosophie

- Kein Sound (Konfiguration ausdrücklich „ohne Audio" im MVP).
- Kein Bounce, keine Benachrichtigungszentrale, kein Badge.
- Die einzige „Aufdringlichkeit" ist die Anwesenheit in der Bildschirmecke
  für wenige Sekunden.

## Barrierefreiheit

- Text-Kontrast auf hudWindow-Material ≥ 4,5:1 (Prüfung mit Accessibility
  Inspector).
- Alle Texte über lokalisierte Strings (de/en ab MVP: de).
- Keine reinen GIF-Informationen: jede Übung hat zwingend Titel + Text
  (Fallback, falls Animation nicht geladen werden kann).
