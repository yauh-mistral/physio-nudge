# 06 — Configuration and Data

## Storage Overview

All app data lives in
`~/Library/Application Support/PhysioNudge/`, split into plain JSON
files (no Core Data in MVP). The exact file layout is an implementation
detail; the requirement that matters: **removing the app must remove
everything** — dragging the app to the Trash must leave no leftovers in
Application Support (see NFR-16). The uninstall story must be documented
in the README (delete the app bundle + one folder).

| Data | Content | Mutable via |
|------|---------|-------------|
| Library | exercises + profiles | Library UI and/or direct file editing |
| Nudges | nudge definitions (profile, schedule, start mode, delay) | Nudges UI and/or file editing |
| Preferences | corner, screen-share suppression, pause | Preferences UI |
| Statistics log | completed exercises (timestamp, exercise, profile, reps/seconds) | app only |

Direct file editing remains a first-class way to create content (the key
user is a developer); the UI must reload changes without restart.

## Library Schema (library.json)

```json
{
  "exercises": [
    {
      "id": "neck-nod",
      "title": "Yes",
      "instruction": "Slowly nod your head up and down, chin to chest and back.",
      "visual": { "type": "gif", "src": "neck-nod.gif" },
      "durationSeconds": 30
    },
    {
      "id": "neck-tilt",
      "title": "Maybe",
      "instruction": "Tilt your ear toward your shoulder, alternating sides.",
      "visual": { "type": "images", "start": "neck-tilt-start.png", "end": "neck-tilt-end.png" },
      "reps": 10
    }
  ],
  "profiles": [
    { "id": "cervical-mobility", "name": "Cervical Mobility",
      "exercises": ["neck-nod", "neck-turn", "neck-tilt"] }
  ]
}
```

Validation rules:

- JSON must be decodable; otherwise the library is empty, the app keeps
  running, and a text-fallback nudge is shown.
- Exercises with missing/corrupt visual files are skipped or fall back
  to text-only display; never a crash.

## Nudge Schema (nudges.json)

```json
{
  "nudges": [
    {
      "id": "hourly-hws",
      "profile": "cervical-mobility",
      "schedule": { "type": "interval", "minutes": 60 },
      "startMode": "auto",
      "autoDelaySeconds": 10
    },
    {
      "id": "afternoon",
      "profile": "cervical-mobility",
      "schedule": { "type": "hourly", "from": "08:00", "to": "16:00" },
      "startMode": "click"
    },
    {
      "id": "fixed",
      "profile": "cervical-mobility",
      "schedule": { "type": "at", "times": ["10:00", "14:00", "18:00"] },
      "startMode": "auto",
      "autoDelaySeconds": 30
    }
  ]
}
```

Schedule types (cron-like, MVP set):

| Type | Fields | Meaning |
|------|--------|---------|
| interval | minutes | every N minutes while the app runs |
| hourly | from, to | every hour between from and to (inclusive) |
| at | times | at fixed clock times |

## Media Files

Stored next to the library file in the same application-support folder
(plus shipped defaults in the app bundle, which user files override).
File names are resolved relative to the folder of the library file.
