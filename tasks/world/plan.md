# Implementation Plan: world (the farm)

## Overview

Build the farm's logic from [SPEC-world.md](../../SPEC-world.md). `FarmBuilder.farm(_:days:at:)` reads the prayer log and the score and returns a `Farm` with today's plot, the five-segment ring, the week (Sunday to Saturday), the Hijri month and the unlocked buildings. Each plot carries an art name so placeholder images can be swapped for the final art. Nothing is stored and nothing is drawn here; drawing happens in the app and widgets later. Pure Swift in `QawwamCore`, tested on Linux in CI, written test-first (tests pushed red, then the code green).

## Architecture Decisions

- **Reuse what exists.** A plot's stage and state come from `Scoring`'s `DayScore` (prayed count, on-time count, complete, closed), and the ring comes from `PrayerLog.status`. The farm can't disagree with the score.
- **Days outside the history.** Days after today are `future`, and days before the user's first day are `unused` (bare soil, never wilted). The first day is the oldest prayer day passed in.
- **Hijri months use Foundation's Umm al-Qura calendar** (`Calendar(identifier: .islamicUmmAlQura)`), already used and verified on Linux by `prayer-times`. Month lengths are checked against the official Riyadh 2027 export's Hijri column, which is already in the test fixtures.
- **Art names** follow one pattern, `palm.stage<N>` plus `.fruit` or `.wilted`, with `soil` for an empty plot. `Plot.allArtNames` lists every name the code can produce, so the artist has an exact list.
- **3D and interactive farm** (Meshari, 2026-11-10): this module stays renderer-free. Each plot gets a grid position and an asset name that names a 3D model in the app and a still image in widgets, so the 3D scene and the widgets read the same data.
- **Buildings** map one to one onto `Score.badges`, in unlock order.

## Task List

See [todo.md](todo.md).

1. A plot's stage, state and art name (S)
2. Today's ring (XS)
3. The week, Sunday to Saturday (S)
   - Checkpoint: today and week done
4. The Hijri month (S)
5. Buildings from badges (XS)
6. The whole farm, the art list and a real Riyadh month (S)
   - Checkpoint: complete

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Foundation's Umm al-Qura calendar differs from the official one on some month boundary | Med: a month view shifted by a day | Test month starts and lengths against the official Riyadh 2027 export |
| Time zone mix-ups put a plot on the wrong day | Med | All day maths uses `DayKey` and the Asia/Riyadh calendar, with tests around midnight and Fajr |
| Art names change after the art is drawn | Low | One generated list of names, and renaming is an ask-first item in the spec |

## Open Questions

None. Meshari answered all three spec questions on 2026-11-10.
