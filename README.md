# physio-nudge

Nudges the user in customizable intervals to perform some physio exercises on macOS —
via a small, non-intrusive corner overlay that plays a sequence of 1–3 exercise GIFs.

**Das Wichtigste zuerst:** die vollständigen Anforderungen liegen im
[requirements/](requirements/)-Ordner — Vision, Overlay-UX-Spec,
GIF-/Content-Vorgaben, Architektur- und MVP-Akzeptanzkriterien.

## Kurzfassung

- Menüleisten-App (kein Dock-Icon), zeigt im Intervall (Default 60 min) ein
  300×300-Overlay in wählbarer Bildschirmecke
- **Non-activating:** stiehlt keinem Fenster den Fokus; sichtbar auf allen
  Desktops und über Fullscreen-Apps
- Spielt 1–3 GIFs pro Übung + Titel + Anleitung, blendet sich selbst aus
- Übungen: exercises.json + GIFs (Nutzerordner oder App-Bundle)
- 100 % lokal: kein Netzwerk, keine Telemetrie

## Status

Requirements: vollständig (siehe requirements/). Implementierung: MVP in Arbeit —
Swift/AppKit-Code in Sources/, Build via Scripts/make-app.sh.

## Lizenz

MIT (siehe LICENSE).
