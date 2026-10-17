# physio-nudge

Nudges the user — on cron-like, user-defined schedules — to perform
movement exercises on macOS, via a small, non-intrusive corner overlay
that plays a user-composed **profile** of exercises.

**The essentials first:** the complete requirements live in the
[requirements/](requirements/) folder — vision, overlay UX spec,
content/visual guidelines, architecture, and MVP acceptance criteria
(all in English).

## In Short

- Menu-bar app (no Dock icon); cron-like nudges: "every 60 min",
  "hourly 08:00–16:00", "at 10:00, 14:00, 18:00"
- **Non-activating:** steals focus from no window; present on all
  desktops and above full-screen apps; never appears during screen
  sharing (setting-gated)
- Plays a profile (1..n exercises) with title, instruction, and a simple
  visual (animated GIF or start/end images) per exercise
- Start modes: **auto perform** (configurable 0–60 s delay) or
  **start by click**; "No" dismisses; "All done?" confirms completion
- **Library** (exercises + profiles), **Nudges** (schedules), and
  **Statistics** (completed exercises only) — configurable via UI or
  plain JSON files
- 100 % local: no network, no telemetry; clean one-folder uninstall

## Build & Run It Yourself

The app is not yet distributed as a binary — build it locally on your
Mac (macOS 13+, Xcode or its command line tools):

```bash
git clone https://github.com/yauh-mistral/physio-nudge.git
cd physio-nudge
bash Scripts/make-app.sh
```

That single command builds, bundles, and launches `PhysioNudge.app`
(the menu-bar icon appears — the app intentionally has no Dock icon).
You can also build and run it from Xcode like any SwiftPM project.

**Full guide — including Xcode steps, local "installation" to
/Applications, the Gatekeeper note for unsigned apps, updating, and
uninstalling: [docs/build.md](docs/build.md)**

Prebuilt binaries will appear on the Releases page later.

## Status

Requirements: complete, reworked with the key user (see requirements/).
Implementation: the initial single-interval MVP exists in Sources/;
the profile/nudge-scheduler rework (M1–M3, see
[requirements/09](requirements/09-mvp-and-acceptance-criteria.md)) is
the next step.

## License

MIT (see LICENSE).
