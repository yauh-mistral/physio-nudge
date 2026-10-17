# 07 — Nichtfunktionale Anforderungen

## Performance

**NFR-01 (M)** — Idle-CPU nahe 0 %: kein Polling, ein einziger Timer.
**NFR-02 (M)** — RAM < 60 MB im Dauerbetrieb (AppKit, kein Electron).
**NFR-03 (M)** — GIFs werden erst beim Anzeigen des Overlays geladen und
nach dem Schließen entladen (Frames werden freigegeben).
**NFR-04 (M)** — App-Start < 1 s bis Menüleisten-Icon erscheint.

## Verhalten gegenüber dem System

**NFR-05 (M)** — Keine Sonderberechtigungen: keine Accessibility-Zugriffe,
kein Screen-Recording, keine Full-Disk-Access, keine Netzwerk-Freigaben.
**NFR-06 (M)** — Fokus-Neutralität: das Overlay aktiviert niemals ein Fenster
(kann an `canBecomeKey == false` für das Panel geprüft werden).
**NFR-07 (M)** — macOS 13 (Ventura) bis aktuell; Universal Binary (Apple Silicon + Intel).

## Robustheit

**NFR-08 (M)** — Defekte/fehlende GIFs führen nie zum Absturz: Übung wird
übersprungen bzw. durch Icon + Text ersetzt.
**NFR-09 (M)** — Ungültige exercises.json → Text-Fallback, App läuft weiter.
**NFR-10 (M)** — Sleep/Wake, Monitor-Wechsel (auch RDP/Diskrete GPUs) dürfen
den Timer nicht entkoppeln (Neukalibrierung per Wake-Notification).
**NFR-11 (M)** — Niemals zwei gleichzeitige Overlays.

## Privatsphäre

**NFR-12 (M)** — Keine Netzwerkverbindung, keine Telemetrie, keine
Aktivitätsaufzeichnung (klar dokumentiert im README).

## Barrierefreiheit

**NFR-13 (M)** — Textkontrast im Overlay ≥ 4,5:1; Reduced-Motion respektieren
(Sollen: bei „Bewegung reduzieren" GIF-Autoplay durch Standbild + Text ersetzen).
**NFR-14 (M)** — Menü vollständig per Tastatur bedienbar (Standard-NSMenu).
