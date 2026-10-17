# 03 — Functional Requirements

Prioritization: M = Must (MVP), S = Should, C = Could, W = Won't (this release).

## Terminology

- **Exercise** — the atomic movement unit, with title, instruction, and
  a visual (GIF or start/end images), performed with either repetitions
  (e.g. 10x) or a duration (e.g. 60 s).
- **Profile** — a named, ordered sequence of 1..n exercises. A profile
  with a single exercise is fully valid.
- **Nudge** — a scheduled event that presents one profile. A nudge is
  defined by: assigned profile + schedule + start mode (auto/click) +
  auto-start delay.
- **Group Profile** (post-MVP) — a named subset of profiles to
  constrain later randomization ("shuffle").

## App Base Behavior

**FR-01 (M)** — The app runs as a background app: no Dock icon, the
menu-bar icon is its only presence.

Acceptance: after launch there is no Dock icon; the menu-bar icon works.

**FR-02 (M)** — Multiple nudges can coexist, each with its own schedule.
Schedules are cron-like: "every N minutes", "hourly between HH:MM and
HH:MM", "at HH:MM, HH:MM, HH:MM".

Acceptance: two nudges ("hourly 08:00–16:00" and "at 10:00, 14:00, 18:00")
can be created and both fire as configured.

**FR-03 (M)** — If two nudges fire at the same minute, they are executed
sequentially, ordered alphabetically by profile name. Never two overlays
at once.

**FR-04 (M)** — A nudge presents its profile: the exercises run in
sequence; each shows its visual (GIF animation or start/end images),
title, and instruction, for its configured reps or duration.

Acceptance: a profile with 3 exercises shows all 3 in order; a 60 s
exercise stays for 60 s.

**FR-05 (M)** — Per exercise, the visual is one animated GIF **or** two
images (start position, end position) that gently cross-fade. Missing or
corrupt files never crash: the exercise falls back to icon + text.

**FR-06 (M)** — Start modes per nudge:
- **Auto perform** — the sequence starts automatically after a
  configurable delay of 0–60 s (counting from overlay appearance).
- **Start by click** — the sequence starts when the user clicks Start.

Acceptance: with delay 10 s, the sequence begins 10 s after the overlay
appears; in click mode nothing runs until Start is clicked.

**FR-07 (M)** — The overlay is non-activating: it never becomes key or
main, never takes focus from the active window, on any Space and over
the user's own full-screen content.

**FR-08 (M)** — The overlay is dismissible: a "No" button ("I'm not
doing this") closes the overlay. There is no snooze / remind-again.

Acceptance: "No" closes the overlay immediately; no re-prompt occurs.

**FR-09 (M)** — Completion confirmation: when a sequence finishes
(auto-performed or click-started), the overlay asks "All done?" with
Yes/No.

Acceptance: both answers close the overlay; only "Yes" is logged.

**FR-10 (M)** — The scheduler recalibrates after system sleep/wake and
display changes; missed schedules fire within a bounded catch-up
window (max one missed occurrence per nudge), never duplicated.

Acceptance: after a 30 min sleep the next occurrence is within one
interval of wake; no double-firing.

**FR-11 (M)** — Screen-share suppression setting in Preferences:
"Never nudge during screen sharing" (default on). When enabled, nudges
are suppressed while the screen is being captured/shared and resume
(at most one queued occurrence) when sharing ends. When disabled,
nudges show regardless of sharing/video calls.

Acceptance: with the setting on and an active screen share, no overlay
appears; after sharing ends, at most one queued nudge fires.

## Library, Nudges, Statistics

**FR-12 (M)** — The app has a **Settings UI** (a regular window) with
sections **Nudges** and **Preferences**.

**FR-13 (M)** — Nudges section: list, create, edit, delete nudges
(profile assignment, schedule, start mode, delay).

**FR-14 (M)** — Preferences section: overlay corner (bottom/top, left/
right), screen-share suppression toggle, global pause/resume.

**FR-15 (M)** — **Library** (separate menu-bar entry and window):
manage exercises (title, instruction, visual files, reps or duration)
and profiles (ordered exercise lists). Creating content via direct file
editing must remain possible.

**FR-16 (M)** — **Statistics** (separate menu-bar entry and window):
log of completed exercises only. No nudges are tracked, and "No"
answers do not appear in the statistics. A log entry records: exercise,
profile, timestamp, and the performed volume (reps or seconds).
Aggregation per profile and per day (e.g. "Cervical Mobility — Mon:
10:13, 13:05, 16:00 — total 180 s / 40 reps").

Acceptance: completing a 3x60 s profile and confirming "Yes" shows
entries summing to 180 s; pressing "No" leaves no trace.

**FR-17 (M)** — The default library ships with profile **Cervical
Mobility**: three exercises — "Yes" (head nod up/down), "No" (head turn
left/right), "Maybe" (ear toward shoulder, alternating) — covering
the three movement dimensions of the neck.

## Should / Could / Won't

**FR-18 (S)** — Overlay dismissible by click anywhere on it (in
addition to the "No" button).

**FR-19 (S)** — Reduced Motion: replace animations with a static
start-position image + text.

**FR-20 (C)** — Launch at Login (SMAppService).

**FR-21 (C)** — Group Profiles ("Mobility" etc.) as named subsets of
profiles; constrains later shuffle.

**FR-22 (C)** — Shuffle: instead of a fixed profile assignment, a nudge
picks a random profile (from a group) at fire time; no immediate
repetition.

**FR-23 (W)** — iOS sync, cloud, telemetry — deliberately never.

**FR-24 (W)** — Onboarding flows for third-party users (version 2).
