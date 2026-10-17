# Requirements — physio-nudge

This directory contains the complete requirements for physio-nudge, the
macOS menu-bar app that presents cron-like, non-intrusive movement
nudges: small corner overlays playing user-composable exercise profiles.

The requirements were reworked in an interview with the key user and are
written in English throughout (repository language: English).

## Documents

| # | Document | Content |
|---|----------|---------|
| 01 | vision-and-target-audience.md | problem, vision, key user, success measures |
| 02 | competitive-differentiation.md | comparison with Time Out, Stretchly, LookAway; positioning |
| 03 | functional-requirements.md | FR list with IDs, MoSCoW priorities, acceptance criteria |
| 04 | overlay-ux-spec.md | behavior spec of the overlay (the core) |
| 05 | exercise-content-and-visuals.md | data model, GIF/start-end visuals, content guidelines |
| 06 | configuration-and-data.md | JSON schemas (library, nudges), storage, clean removal |
| 07 | non-functional-requirements.md | performance, privacy, robustness, accessibility |
| 08 | technical-architecture.md | architecture decisions (NSPanel, ImageIO, scheduler, stores) |
| 09 | mvp-and-acceptance-criteria.md | milestones M1–M3, MVP scope, acceptance checklist |

## Recommended Reading Order

01 → 03 → 04 → 05 (product decisions) plus
02 → 06 → 07 → 08 → 09 (completeness).

## Guiding Principle

> The nudge must never disturb, but it must not be overlooked either.
> Anything that interrupts the user (focus, flow, meetings) is a bug.

## Core Concepts

- **Exercise** — atomic movement unit (reps or duration), with GIF or
  start/end visual.
- **Profile** — ordered sequence of 1..n exercises.
- **Nudge** — schedule entry (cron-like) that presents one profile.
- **Statistics** — completed exercises only; "No" leaves no trace.
