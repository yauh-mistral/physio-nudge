# 09 — MVP Scope and Acceptance Criteria

## Milestones

**M1 — Core loop (engine):** scheduler with all three schedule types,
profile playback (sequence, start modes, "All done?"), completion log,
default Cervical Mobility library, JSON-configured nudges.

**M2 — Product for the key user (minimum acceptable product):**
everything in M1 **plus the UI**: Settings window (Nudges, Preferences),
Library window, Statistics window. **M2 is the MVP — the key user needs
a UI; without it there is no product for him.**

**M3 — Refinement:** screen-share suppression setting with reliable
detection, Reduced Motion polish, menu extras, release packaging.

Post-MVP: Group Profiles, Shuffle, onboarding, launch-at-login.

## MVP Scope (all "Must" FRs)

FR-01 … FR-17: background app, cron-like nudges, profile playback with
GIF/start-end visuals, auto/click start, No button, "All done?" log,
Library/Statistics UI, default Cervical Mobility content, clean
uninstall.

## Acceptance Checklist (Release Check)

| # | Criterion | Evidence |
|---|-----------|----------|
| A1 | `bash Scripts/make-app.sh` produces a runnable .app | build without errors, app starts |
| A2 | No Dock icon after launch | visual check |
| A3 | Nudge "every 1 min" fires reliably | 5 min observation |
| A4 | "hourly 08:00–16:00" and "at 10:00/14:00/18:00" fire at the right times | clock check |
| A5 | Two simultaneous nudges run sequentially, alphabetically by profile name | test with two profiles "A…", "B…" |
| A6 | Typing user in an editor loses **no** focus/cursor when the overlay appears | test in TextEdit + VS Code |
| A7 | Overlay visible above full-screen video (own screen) | manual: trigger nudge in full screen |
| A8 | With "Never nudge during screen sharing" on, no overlay during an active share; one queued occurrence fires after sharing ends | screen-share test |
| A9 | Profile with 3 exercises shows all 3 in order; reps/duration displayed correctly | test library |
| A10 | Auto perform with delay 10 s starts the sequence after 10 s; start-by-click waits for click | stopwatch |
| A11 | "No" closes the overlay, no re-prompt, no statistics entry | UI test |
| A12 | "All done? Yes" logs the performed exercises with timestamp and volume; "No" logs nothing | statistics window check |
| A13 | Missing/corrupt visual → exercise falls back to text, no crash | rename a GIF |
| A14 | Invalid library.json → text fallback, app keeps running | delete/corrupt file |
| A15 | Sleep 30 min → wake: next occurrence within one interval, no doubles | sleep test |
| A16 | Settings UI: create/edit/delete a nudge with all schedule types | UI walkthrough |
| A17 | Library UI: create exercise + profile, reorder exercises | UI walkthrough |
| A18 | Statistics: "Cervical Mobility — Day 1, 10:13/13:05/16:00 — 180 s / 40 reps" style aggregation | after 3 confirmed sessions |
| A19 | Idle CPU ~0 %, RAM < 80 MB | 1 h Activity Monitor |
| A20 | No network traffic of the app | Little Snitch / lsof |
| A21 | Uninstall: delete app + PhysioNudge folder → no leftovers in ~/Library | search after removal |

## Explicitly Outside MVP

FR-18 … FR-24 (click-to-dismiss extras, launch-at-login, group profiles,
shuffle), Windows/Linux, auto-updater, App Store distribution,
onboarding for third parties.

## Definition of Done (per feature)

Code + passing test per the acceptance checklist + update of the
corresponding requirements document whenever behavior changes.
