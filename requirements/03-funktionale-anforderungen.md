# 03 — Funktionale Anforderungen

Priorisierung: M = Must (MVP), S = Should, C = Could, W = Won't (dieses Release).

## App-Grundverhalten

**FR-01 (M)** — Die App läuft als Hintergrund-App: kein Dock-Icon, Menüleisten-Icon als einzige sichtbare Präsenz.
Akzeptanz: Nach dem Start existiert kein Dock-Icon; das Menüleisten-Icon ist bedienbar.

**FR-02 (M)** — Die App zeigt im konfigurierbaren Intervall (Default 60 min) automatisch das Overlay mit einer zufällig gewählten Übung.
Akzeptanz: Bei Intervall 1 min erscheint das Overlay zuverlässig minütlich.

**FR-03 (M)** — Pro Übung spielt das Overlay die hinterlegte GIF-Sequenz (1–3 GIFs) nacheinander ab, mit Titel und Anleitungstext.
Akzeptanz: Übung mit 2 GIFs zeigt beide nacheinander in konfigurierbarer Dauer.

**FR-04 (M)** — Das Overlay blendet sich nach der Sequenz automatisch aus (Fade-out), ohne Interaktion.
Akzeptanz: Kein Zustand, in dem das Overlay dauerhaft offen bleibt.

**FR-05 (M)** — Menü: „Pause/Fortsetzen" unterbindet und resumed die automatischen Overlays.
Akzeptanz: Im Pause-Zustand erscheint kein Overlay; „Fortsetzen" startet den Timer neu.

**FR-06 (M)** — Menü: „Jetzt üben" zeigt sofort das nächste Overlay, ohne den Timer zu verändern.
Akzeptanz: Nach manuellem Overlay erscheint das nächste reguläre Overlay wie geplant.

**FR-07 (M)** — Menü: Intervall-Auswahl (15/30/45/60/90 min) mit sichtbarer Auswahl (Checkmark).
Akzeptanz: Gewähltes Intervall ist aktiv, Neustart der App nicht nötig.

**FR-08 (M)** — Menü: Ecken-Auswahl (unten rechts/links, oben rechts/links) für die Overlay-Position.
Akzeptanz: Das nächste Overlay erscheint in der gewählten Ecke mit 24 px Rand.

**FR-09 (M)** — Der Timer wird nach dem Aufwachen aus dem System-Sleep neu kalibriert.
Akzeptanz: Nach Sleep/Wake erscheint das Overlay binnen des vollen Intervalls, nicht doppelt oder nie.

**FR-10 (M)** — Übungen werden aus einer exercises.json geladen; Übungen mit fehlenden GIF-Dateien werden übersprungen.
Akzeptanz: Katalog mit 3 Übungen, 1 ohne Dateien → nur 2 stehen zur Auswahl.

**FR-11 (M)** — Ohne verwertbare GIFs zeigt das Overlay einen Text-Fallback („Zeit für eine Pause!" + Hinweis auf das README).

## Should / Could

**FR-12 (S)** — Einstellungen (Intervall, Ecke, Pause) persistieren über Neustarts (UserDefaults).
**FR-13 (S)** — Overlay ist per Klick wegklickbar (Schließen-Button oder Klick ins Overlay).
**FR-14 (S)** — Overlay bleibt aus, während ein Meeting/Screen-Share läuft (CGWindowList-Heuristik) — konfigurierbar.
**FR-15 (C)** — „Bei Login starten" per SMAppService.
**FR-16 (C)** — Übung mitgemacht-Zähler im Menü („Heute: 5 Übungen").
**FR-17 (W)** — iOS-Sync, Cloud, Telemetrie — bewusst nicht.
