# 09 — MVP-Umfang und Akzeptanzkriterien

## MVP-Umfang (alles „Must" aus FR-01 bis FR-11)

1. Hintergrund-Menüleisten-App ohne Dock-Icon
2. Intervall-Timer mit Menü-Konfiguration (15–90 min)
3. Ecken-Overlay mit GIF-Sequenz, Titel, Anleitung
4. Automatisches Ausblenden, Pause, „Jetzt üben"
5. Übungskatalog aus exercises.json (App Support > Bundle)
6. Sleep/Wake-Kalibrierung

## Abnahmeliste (Release-Check)

| # | Kriterium | Nachweis |
|---|-----------|----------|
| A1 | bash Scripts/make-app.sh erzeugt lauffähige .app | Build ohne Fehler, App startet |
| A2 | Kein Dock-Icon nach Start | visuelle Prüfung |
| A3 | Overlay erscheint im gewählten Intervall | Intervall 1 min, Beobachtung 5 min |
| A4 | Tippender Nutzer in einem Editor verliert beim Einblenden **keinen** Fokus/Cursor | Test in TextEdit + VS Code |
| A5 | Overlay sichtbar über Fullscreen-Video (YouTube Vollbild) | manuell: „Jetzt üben" im Vollbild |
| A6 | Übung mit 2 GIFs spielt beide nacheinander ab | Testdatensatz |
| A7 | Overlay verschwindet automatisch (Sequenz × perGifSeconds + 1 s) | Stoppuhr |
| A8 | Pause unterbindet Overlays; „Jetzt üben" funktioniert weiter | Menü-Test |
| A9 | GIF-Datei umbenennen → Übung wird übersprungen, keine andere Übung beschädigt | Katalog-Test |
| A10 | exercises.json löschen → Text-Fallback-Overlay | Test |
| A11 | Sleep 10 min → Wake: nächstes Overlay im vollen Intervall | Sleep-Test |
| A12 | Keine zwei Overlays gleichzeitig („Jetzt üben" 3× hintereinander) | Spam-Test |
| A13 | Idle-CPU im Activity Monitor ~0 %, RAM < 60 MB | 1 h Messung |
| A14 | Kein Netzwerk-Traffic der App | Little Snitch / lsof |

## Explizit außerhalb des MVP

FR-12 bis FR-17 (Persistenz, Meeting-Detection, Autostart, Statistik),
Windows/Linux, Autoupdater, App-Store-Distribution.

## Definition of Done (pro Feature)

Code + funktionierender Test lt. Abnahmeliste + Update im zugehörigen
Requirements-Dokument, wenn sich Verhalten ändert.
