# 05 — Exercise Content and Visuals

## Data Model

An **exercise** consists of:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | String | yes | stable identifier |
| title | String | yes | exercise name, ≤ 30 characters |
| instruction | String | yes | 1–2 sentences, ≤ 120 characters |
| visual | Object | yes | animation description (see below) |
| reps | Int | one of reps/duration | repetitions (e.g. 10) |
| durationSeconds | Int | one of reps/duration | duration (e.g. 60) |

Exactly one of `reps` or `durationSeconds` is set per exercise.

A **profile** consists of:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | String | yes | stable identifier |
| name | String | yes | profile name (drives alphabetical collision order, FR-03) |
| exercises | [String] | yes | ordered list of exercise ids, 1..n |

## Visual Formats

Two supported formats per exercise, chosen for extensibility — adding
new exercises later must stay trivially easy, which is why plain media
files are preferred over app-rendered animation:

1. **Animated GIF** (preferred for movements): shows the movement
   execution, front or side view.
2. **Start/end images** (PNG): two images — start position and end
   position — that gently cross-fade back and forth. Good enough for
   slow, simple movements; trivially easy to produce.

GIF specification:

| Property | Requirement | Rationale |
|----------|-------------|-----------|
| Format | GIF89a, animated | wide compatibility, no codec needed |
| Resolution | 400–480 px height | sharp in the 300-pt panel at 2x |
| File size | ≤ 2 MB | overlay must appear instantly, no loading flash |
| Loop duration | 4–8 s | repetition recognizable, not hectic |
| Frame duration | 60–100 ms/frame | fluid, no CPU spikes |
| Background | transparent preferred | harmonizes with hudWindow material |

## Content Status

There are no GIFs today. The initial visuals for the Cervical Mobility
profile will be produced together as part of the build: simple, calm
guides that help perform the movement correctly — light, restrained
animation, no gimmicks. Until then, start/end PNGs are acceptable.

## Content Guidelines

1. **Tone**: friendly, short imperative ("Slowly tilt your head toward
   your ear").
2. **Safety**: no injury-prone exercises without a warning; load
   hints in the instruction ("never pull into pain").
3. **Language**: English everywhere (UI, content, docs) per the
   all-English repository decision.
4. **Initial set**: Cervical Mobility — "Yes" (nod up/down), "No"
   (turn left/right), "Maybe" (ear to shoulder, alternating). This is
   the start construct and will be extended (shoulders, posture
   changes, circulation) over time.

## Licensing / Sources

- Only self-made visuals or clearly licensed content (CC0/CC-BY with
  attribution in a CREDITS.md next to the media files).
- No sourced Giphy/Tenor GIFs without cleared license.
- Exercise visuals are not committed to git if they are personal;
  the repository ships placeholders plus the default Cervical Mobility
  set.
