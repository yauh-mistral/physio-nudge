# Requirements — physio-nudge

Dieses Verzeichnis enthält die vollständigen Anforderungen für physio-nudge,
die macOS-Menüleisten-App, die in konfigurierbaren Intervallen ein dezentes
Ecken-Overlay mit kurzen GIF-Sequenzen für Dehn- und Physio-Übungen zeigt.

## Dokumente

| # | Dokument | Inhalt |
|---|----------|--------|
| 01 | vision-und-zielgruppe.md | Problem, Vision, Zielgruppe, Erfolgsmaße |
| 02 | wettbewerbsabgrenzung.md | Vergleich mit Time Out, Stretchly, LookAway; Positionierung |
| 03 | funktionale-anforderungen.md | FR-Liste mit IDs, Prioritäten (MoSCoW), Akzeptanzkriterien |
| 04 | overlay-ux-spec.md | **Verhaltens-Spec des Overlays** (das Herzstück) |
| 05 | uebungs-inhalte.md | Übungsdatenmodell, GIF-Spezifikation, Content-Richtlinien |
| 06 | konfiguration-und-daten.md | Konfigurationsschema, Speicherorte, zukünftige Settings |
| 07 | nichtfunktionale-anforderungen.md | Performance, Privatsphäre, Robustheit, Barrierefreiheit |
| 08 | technische-architektur.md | Architekturentscheidungen (NSPanel, ImageIO, SwiftPM) |
| 09 | mvp-und-akzeptanzkriterien.md | MVP-Umfang und finale Abnahmeliste |

## Empfohlene Lesereihenfolge

01 → 03 → 04 → 05 (für Produktentscheidungen) bzw. zusätzlich
02 → 06 → 07 → 08 → 09 (für Vollständigkeit).

## Leitprinzip

> Der Nudge darf niemals stören, aber er darf auch nicht übersehen werden.
> Alles, was den Nutzer unterbricht (Fokus, Flow, Meetings), ist ein Bug.
