# 07 — Non-Functional Requirements

## Performance

**NFR-01 (M)** — Idle CPU near 0 %: no polling, scheduler based on
timed events.

**NFR-02 (M)** — RAM < 80 MB in continuous operation (AppKit, no
Electron; the limit rises from 60 MB because of the settings UI).

**NFR-03 (M)** — Visuals are loaded only when the overlay shows them
and released after it closes.

**NFR-04 (M)** — App launch < 1 s until the menu-bar icon appears.

## System Behavior

**NFR-05 (M)** — No special permissions: no accessibility access, no
screen recording, no full-disk access, no network entitlements.
(Screen-share suppression must work without capture APIs — e.g. via
the system's screen-capture indicator state — or degrade gracefully;
if reliable detection requires permissions, the feature stays
setting-gated and documented.)

**NFR-06 (M)** — Focus neutrality: the overlay never activates any
window (verifiable via `canBecomeKey == false` on the panel).

**NFR-07 (M)** — macOS 13 (Ventura) to current; universal binary
(Apple Silicon + Intel).

## Robustness

**NFR-08 (M)** — Missing/corrupt visuals never crash: the exercise is
skipped or reduced to icon + text.

**NFR-09 (M)** — Invalid library/nudge JSON → text fallback, app keeps
running.

**NFR-10 (M)** — Sleep/wake and display changes never decouple the
scheduler (recalibration via wake notifications).

**NFR-11 (M)** — Never two simultaneous overlays.

**NFR-12 (M)** — Concurrency: overlapping nudges are queued and run
sequentially (alphabetical profile order); the queue is bounded and
loses nothing on sleep/wake.

## Privacy

**NFR-13 (M)** — No network connections, no telemetry, no activity
tracking beyond the local completion log (documented in the README).

## Accessibility

**NFR-14 (M)** — Text contrast in the overlay ≥ 4.5:1; Reduced Motion
respected (should: animation replaced by static image + text).

**NFR-15 (M)** — Fully keyboard-operable settings and menu.

## Clean Removal

**NFR-16 (M)** — Uninstalling = dragging the app bundle to the Trash.
The app stores everything in exactly one folder in Application Support
and must not scatter data elsewhere (no UserDefaults-based content, no
caches outside the folder). The README documents one-step removal
("delete app bundle and the PhysioNudge folder").

Acceptance: after app removal and Trash emptying, no PhysioNudge traces
remain anywhere in ~/Library.

## Openness

**NFR-17 (M)** — Open source (MIT), repository and all content in
English.
