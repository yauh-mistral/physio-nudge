# 04 — Overlay UX Spec (The Core)

## Base Principle

The overlay is a **non-activating corner overlay**: it appears without
any window losing focus, is present on all Spaces and above the user's
own full-screen content, and disappears by itself. Its goal is
**presence, not foreground activity**: it behaves like a notification,
never a dialog.

## Visual Specification

| Property | Value |
|----------|-------|
| Size | 300 × 300 pt |
| Position | selectable corner, 24 pt from visible screen area (mind the Dock) |
| Background | NSVisualEffectView, hudWindow material, rounded (radius 16) |
| Title | system font 14 pt semibold, white |
| Instruction | system font 12 pt, light gray, centered, max width 260 pt |
| Visual area | proportionally scaled, top of the stack |
| Shadow | enabled (separates overlay from content) |

## Sequence Behavior

| Phase | Behavior |
|-------|----------|
| Appear | fade-in 350 ms (alphaValue 0 → 1), no activation |
| Exercise phase | visual (GIF loop or start/end cross-fade) + title + instruction + progress ("2 / 3", "10x", "60 s") |
| Between exercises | hard switch; next exercise starts immediately |
| Confirm | "All done?" with Yes/No at sequence end |
| Disappear | fade-out 300 ms, then the panel is removed entirely |

## Start Modes and Interaction

- **Auto perform**: a countdown (0–60 s, configured per nudge) runs in
  the overlay; the sequence starts when it reaches zero.
- **Start by click**: a Start button in the overlay; nothing runs before
  the click.
- **No button**: always visible; closes the overlay immediately
  ("I'm not doing this now"). No snooze, no re-prompt.
- **All done?**: after the last exercise the overlay asks Yes/No.
  Yes logs the completed exercises; No logs nothing. Both close the
  overlay.

The overlay never becomes key or main: keyboard/click focus of the
running app remains untouched (core acceptance criterion). It must never
appear during video calls or while the user is screen-sharing (when the
suppression setting is enabled) — presence is acceptable, appearing in a
customer's meeting is not.

## Visibility Rules

1. Visible on **all Spaces** (canJoinAllSpaces).
2. Also **above full-screen apps** (fullScreenAuxiliary) — e.g. video in
   full screen: the nudge remains visible.
3. **Not shown** when: app paused, screen locked, screensaver active, or
   (setting enabled) screen capture/share is active.
4. Never two overlays at the same time; simultaneous nudges queue and
   run sequentially in alphabetical profile order (FR-03).

## No-Disturb Philosophy

- No sound in MVP (deliberately "no audio").
- No bounce, no notification center, no badge — the overlay itself is
  the notification.
- The only "intrusiveness" is the presence in a screen corner for the
  duration of the exercise.

## Accessibility

- Text contrast on hudWindow material ≥ 4.5:1 (check with Accessibility
  Inspector).
- All texts via localized string catalogs (English at MVP).
- Every exercise has title + text; the visual is always an addition,
  never the sole information carrier.
