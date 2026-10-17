# 02 — Competitive Differentiation

## Existing Solutions

| App | Approach | Weakness from our perspective |
|-----|----------|------------------------------|
| Time Out (Dejal) | Full-screen dimming + themes, GIF stretch themes | intrusive full-screen overlay, focus on breaks, not exercises |
| Stretchly (OSS) | Full-screen microbreaks, custom exercise texts | no corner mode, no animations, Electron overhead, unsigned on macOS |
| LookAway | Smart pause, posture/blink reminders, ~$19 | eye/posture focus, full-screen breaks, no exercise catalog |
| Healthier, DeskRest, Breather | Break reminders with exercise tips | also full-screen or notification-center approaches |

Note: the key user has not tested these alternatives. This comparison is
based on public documentation; the app is built to satisfy his own needs
first. If competitors inspire improvements — great, but they are not the
benchmark.

## The Gap

None of the established apps combines:

1. a **discreet corner overlay** instead of full-screen dimming,
2. **user-composable profiles** of movement exercises with simple
   animations instead of static tips,
3. **non-activating presence** (no focus loss, no window activation), and
4. **cron-like scheduling** ("hourly between 8 and 16", "at 10, 14, 18").

## Positioning

> physio-nudge is the "nudge" among break apps: present enough to be
> seen, polite enough to never be switched off.

The full-screen overlay of competitors is their accepted interference; we
reverse the premise: the interruption may only be a *reminder*, never a
*block*. Presence is the goal — not foreground activity.

## Possible Competitor Response

Full-screen apps could retrofit a "mini mode". Our advantage is focus:
concentration on movement content (exercise library, profile composition,
calm animations) instead of feature breadth.
