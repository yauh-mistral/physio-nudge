# 08 — Technische Architektur

## Technologie-Stack

- **Sprache:** Swift 5.9, AppKit (bewusst kein SwiftUI für das Overlay-Fenster).
- **Build:** Swift Package Manager; .app-Bundling über Scripts/make-app.sh
  (kein Xcode-Projekt nötig, Versionskontrolle-freundlich).
- **Mindestversion:** macOS 13.

## Warum NSPanel und kein SwiftUI-Window

SwiftUIs Window-API bietet keinen nicht-aktivierenden Overlay-Modus. Der Kern
ist ein NSPanel-Subclass:

```swift
super.init(contentRect: rect,
           styleMask: [.borderless, .nonactivatingPanel], // stiehlt keinen Fokus
           backing: .buffered, defer: false)

isFloatingPanel = true
level = .statusBar                                  // über normalen Fenstern
collectionBehavior = [.canJoinAllSpaces,            // auf jedem Desktop
                      .fullScreenAuxiliary]         // auch über Fullscreen
isOpaque = false
canBecomeKey  → false                               // wird nie aktiv
```

## GIF-Wiedergabe

NSImageView animiert GIFs nicht. Statt eines WKWebView (Overkill, ganzer
Renderer-Prozess) extrahiert GifAnimator Frames über **ImageIO**
(CGImageSource): Frame-Anzahl, Frame-Dauern (kCGImagePropertyGIFDelayTime),
Wiedergabe über einen selbstgetakteten Timer. Zustandslos gegenüber dem
Rest der App.

## Komponentenübersicht

| Komponente | Verantwortung |
|-----------|---------------|
| main.swift | NSApplication-Start, .accessory-Policy (kein Dock-Icon) |
| AppDelegate | Menüleiste, Timer, Overlay-Lebenszyklus, Pause/Intervall/Ecke |
| OverlayPanel | NSPanel-Overlay, Ecken-Positionierung, Fade-in/out |
| OverlayViewController | UI-Aufbau, GIF-Sequenzsteuerung |
| GifAnimator | frame-weise GIF-Wiedergabe via ImageIO |
| ExerciseCatalog | Katalog-Laden (App Support > Bundle), GIF-Existenzfilter |

## Timer-Design

Ein einzelner non-repeating Timer, der nach jedem Event neu geplant wird
(wichtig: Overlay-Dauer geht nicht vom Intervall ab). Neukalibrierung nach
System-Sleep via NSWorkspace.sessionDidWakeNotification.

## Bekannte Grenzen / bewusste Vereinfachungen

- Timer läuft im Default-RunLoop-Mode: während eines offenen Menüs pausiert
  die GIF-Animation kurz (akzeptiert für MVP).
- Kein Multi-Monitor-Placement im MVP: Overlay auf Hauptmonitor, Ecke wählbar.
- no code signing im Repo; für Distribution Developer-ID + Notarisierung nötig.
