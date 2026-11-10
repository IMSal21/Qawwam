# Implementation Plan: scoring

## Overview

Build the scoring module from [SPEC-scoring.md](../../SPEC-scoring.md): points per day, the streak and best streak, the Fajr streak, streak bonuses, badges and level. Everything is one pure function, `Scoring.score(_:days:at:rules:)`, which reads the prayer log and the prayer days and returns a `Score`. Nothing is stored. Pure Swift in `QawwamCore`, tested on Linux in CI, written test-first (tests pushed red, then the code green).

## Architecture Decisions

- **One pass over the days, oldest first.** Score each day, then walk the days in order to build the streaks, bonuses and badges. Every number is derived, so undo and timing changes are always reflected.
- **Day status comes from `PrayerLog.status`.** Scoring never re-implements on time, late or missed; it asks the log, so the two modules can't disagree.
- **Days are checked for gaps.** The days are sorted by `DayKey` and duplicates dropped. If two neighbouring days aren't consecutive dates, the missing day counts as missed, so a caller that forgets a day can't keep a streak alive by mistake.
- **Days that haven't started are ignored.** A day whose Fajr is still in the future contributes nothing.
- **Today:** an open day adds to the streak once all five are prayed and never breaks it while it's open. For the Fajr streak, today breaks it only after sunrise without an on-time Fajr.
- **Streak bonuses** are added every time a running streak reaches 7, 30, 40 or 100. **Badges** are the distinct milestones (3, 7, 30, 40, 100) ever reached.
- **Level** *L* starts at 50 × *L* × (*L* − 1) points, so level 1 is 0–99, level 2 is 100–299 and level 3 is 300–599.

## Task List

See [todo.md](todo.md).

1. Day scores: points, counts, complete and closed (S)
2. The streak and best streak (S)
3. The Fajr streak (S)
   - Checkpoint: streaks done
4. Streak bonuses, badges and total points (S)
5. Level (XS)
6. A real Riyadh month (XS)
   - Checkpoint: complete

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Off by one at a milestone (bonus on day 6 or 8) | High: wrong points | Tests exactly at 2/3, 6/7, 29/30, 39/40 and 99/100 days |
| Today counted as a broken day | High: streak shows 0 all day | Tests for an open day with 0, 3 and 5 prayers logged |
| A missing day in the input keeps a streak alive | Med | Gap detection, with its own test |
| Long histories get slow | Low | One linear pass; a test over 400 days stays well under a second |

## Open Questions

None. Meshari answered all three spec questions on 2026-11-10.
