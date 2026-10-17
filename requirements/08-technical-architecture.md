# 08 — Technical Architecture

## Technology Stack

- **Language:** Swift 5.9, AppKit (deliberately no SwiftUI for the
  overlay window; the settings UI may use AppKit or SwiftUI as
  implementation sees fit).
- **Build:** Swift Package Manager; .app bundling via
  `Scripts/make-app.sh` (no Xcode project needed, VCS-friendly).
- **Minimum:** macOS 13.
- **Data:** plain JSON files in Application Support, one folder, no
  Core Data (see 06 and NFR-16).

## Core Concepts (domain model)

```
Exercise   (title, instruction, visual, reps|duration)
Profile    (name, ordered exercise ids)         1..n exercises
Nudge      (profile ref, schedule, startMode,    cron-like scheduler entry
            autoDelaySeconds)
LogEntry   (timestamp, exercise, profile,       completed exercises only
            reps|seconds)
```

The scheduler evaluates all nudges; simultaneous fires are queued and
executed sequentially in alphabetical profile order. Group Profiles and
Shuffle (post-MVP) extend the profile reference with a group reference —
the data model stays open for them.

## Why NSPanel and not a SwiftUI Window

SwiftUI's window API offers no non-activating overlay mode. The core
remains an NSPanel subclass:

```swift
super.init(contentRect: rect,
           styleMask: [.borderless, .nonactivatingPanel], // steals no focus
           backing: .buffered, defer: false)
isFloatingPanel = true
level = .statusBar                                  // above normal windows
collectionBehavior = [.canJoinAllSpaces,           // on every desktop
                       .fullScreenAuxiliary]        // also above fullscreen
isOpaque = false
canBecomeKey  → false                               // never becomes active
```

## Visual Playback

- **GIF:** NSImageView does not animate GIFs. Instead of a WKWebView
  (overkill, whole renderer process), GifAnimator extracts frames via
  ImageIO (CGImageSource): frame count, frame durations
  (kCGImagePropertyGIFDelayTime), playback via a self-paced timer.
  Stateless toward the rest of the app.
- **Start/end images:** a simple cross-fade between two NSImages on a
  slow loop (e.g. 3 s per direction), reduced to a static image when
  Reduced Motion is on.

## Scheduler Design

One timed event per upcoming nudge occurrence (no polling). Recompute
on: nudge edited, sleep/wake (NSWorkspace.sessionDidWakeNotification),
display changes. Overlay duration does not shorten the interval.

## Component Overview

| Component | Responsibility |
|-----------|----------------|
| main.swift | NSApplication start, .accessory policy (no Dock icon) |
| AppDelegate | menu bar, scheduler wiring, overlay lifecycle |
| SchedulerService | computes next occurrences for all nudges; queue for simultaneous fires |
| OverlayPanel | NSPanel overlay, corner positioning, fade in/out |
| OverlayViewController | sequence control, countdown, start modes, "All done?" |
| GifAnimator | frame-wise GIF playback via ImageIO |
| CrossfadeView | start/end image animation |
| LibraryStore | load/save library.json, media resolution, validation |
| NudgeStore | load/save nudges.json |
| StatisticsStore | append-only completion log |
| SettingsWindowController | Nudges + Preferences sections |
| LibraryWindowController | exercises + profiles management |
| StatisticsWindowController | completed-exercises views |

## Known Limits / Deliberate Simplifications

- Overlay timer runs in the default run-loop mode: while a menu is
  open, the animation briefly pauses (accepted for MVP).
- Single-monitor placement in MVP: overlay on the main screen,
  corner selectable.
- No code signing in the repo; distribution later requires
  Developer ID + notarization.
- Existing Sources are the old single-interval MVP; they will be
  refactored to the scheduler/store architecture during
  implementation of M1/M2 (see 09).
