# 01 — Vision and Target Audience

## Problem

People who work at a screen 6–10 hours a day forget, on their own
initiative, to do neck, shoulder, and back exercises. Calendar or
notification reminders are routinely clicked away; existing break-reminder
apps dim the entire screen, are considered intrusive, and are typically
deactivated after a short time — or never adopted in the first place.

## Vision (Elevator Pitch)

physio-nudge is a macOS menu-bar app that runs invisibly in the
background. On cron-like, user-defined schedules it presents a small,
elegant overlay in a screen corner showing one **profile** — an ordered
sequence of 1..n exercises, each visualized by a simple animation
(GIF or start/end images) with title and short instruction. The overlay
never steals focus from the active window, can start exercises
automatically after a short delay or on click, and disappears by itself.
A lightweight log records which exercises were actually completed.

## Target Audience

- **Primary (key user):** the author himself — a screen worker
  (development, text) who currently has physiotherapy "homework"
  (cervical spine mobilization, circulation) and wants to keep those
  movements as a lasting habit at the desk.
- **Secondary:** other screen workers who want gentle, regular movement
  nudges without breaking their flow.

The app is built for the key user first. Onboarding for third parties is
explicitly **out of scope for MVP** (version 2).

## Jobs to be Done

1. "Remind me to move — reliably, because I lose track of time."
2. "Do not rip me out of my flow: I must stay in control of my screen."
3. "Let me compose my own movement profiles from my exercises."
4. "Let me see which exercises I actually completed."

## Goals

1. The user performs at least 4 of the shown exercise sets per workday.
2. The app stays permanently enabled (it is not abandoned after 2 weeks).
3. The overlay causes zero work interruption (zero focus loss).

## Non-Goals (Anti-Goals)

- No full-screen dimming or screen blocking (deliberate contrast to
  Stretchly/Time Out).
- No activity-tracking database, no gamification dashboard.
- No health-data collection, no diagnoses, no medical advice.
- No adherence enforcement of prescribed exercises: the nudge is a movement
  reminder; prescribed exercises are just one configurable profile.
- No Windows/Linux version in MVP (macOS first, keep the architecture
  portable).
- No shuffle / group profiles in MVP (data model stays open for them).

## Success Measures

Because the user is the key user:

| Metric | Target |
|--------|--------|
| Performed exercises per workday (from the statistics log) | ≥ 4 |
| Still actively used after 4 weeks | yes |
| Perceived as helpful rather than annoying (self-assessment) | yes |
| Measured interruptions (focus loss) caused by the app | 0 |
