# 01 — Vision und Zielgruppe

## Problem

Menschen, die täglich 6–10 Stunden am Bildschirm arbeiten, vergessen aus
eigenem Antrieb, Nacken-, Schulter- und Rückenübungen zu machen. Regelmäßige
Kalender- oder Benachrichtigungs-Erinnerungen werden routiniert weggeklickt;
bestehende Break-Reminder-Apps dimmen den gesamten Bildschirm und gelten
deshalb als aufdringlich — sie werden nach kurzer Zeit deaktiviert.

## Vision (Elevator Pitch)

physio-nudge ist eine unsichtbar im Hintergrund laufende macOS-App, die in
einem konfigurierbaren Intervall (Default: 60 Minuten) ein kleines, elegantes
Overlay in einer Bildschirmecke einblendet und dort für wenige Sekunden eine
Sequenz aus 1–3 GIFs einer Physio-Übung zeigt — mit Titel und kurzer
Anleitung. Das Overlay stiehlt keinem Fenster den Fokus, ist auch über
Fullscreen-Inhalten sichtbar und verschwindet von selbst.

## Zielgruppe

- **Primär:** Bildschirmarbeiter:innen (Entwicklung, Text, Design), die
  regelmäßig Dehnübungen machen wollen, ohne ihren Flow zu unterbrechen.
- **Sekundär:** Menschen mit verspannungsbedingten Beschwerden, die von
  Physiotherapie:innen Übungen verschrieben bekommen haben.

## Ziele

1. Nutzer:in macht pro Arbeitstag ≥ 4 der angezeigten Übungen mit.
2. Die App bleibt dauerhaft aktiviert (nicht nach 2 Wochen deinstalliert).
3. Das Overlay verursacht keinerlei Arbeitsunterbrechung (kein Fokusverlust).

## Nicht-Ziele (Anti-Goals)

- Kein Vollbild-Dimming oder Blockieren des Bildschirms (Abgrenzung zu
  Stretchly/Time Out).
- Keine Aktivitäts-Tracking-Datenbank, kein Gamification-Dashboard.
- Keine Gesundheitsdaten-Erfassung oder Diagnosen.
- Keine Windows/Linux-Version in MVP (macOS first, Architektur portabel halten).

## Erfolgsmaße

| Metrik | Ziel |
|--------|------|
| Mitgemachte Übungen pro Tag (Selbstauskunft im Menü) | ≥ 4 |
| Deaktivierungsrate nach 30 Tagen | < 30 % |
| Gemessene Unterbrechungen (Fokusverlust) | 0 |
