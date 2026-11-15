# Plan: Jumu'ah points

From the Jumu'ah section of [SPEC-scoring.md](../../SPEC-scoring.md) (decision 4).

## Approach

- Everything happens in `Scoring`, which is pure Swift tested on Linux. No new storage: the points come from the log as before.
- `ScoringRules` gains `jumuahMultiplier` (5), `jumuahMissedPenalty` (50) and `jumuahPenaltyStep` (10), so the values sit next to the others.
- The day's points multiply Friday's Dhuhr. A new walk over the closed Fridays works out the penalty and resets the count when Jumu'ah is prayed. The total is added up day by day, kept at zero or more.
- Existing tests whose fixtures run over a Friday get new totals. Each change is written as the old number plus the Friday difference, so it's easy to check.
- The today screen's "+N points today" shows the Friday points with no other change. The Friday penalty appears in the total and level, which the profile screen will show.

## Tasks

1. Tests first (red): every row of the Jumu'ah table and the reset, undo and zero-floor cases. Update the existing totals that include a Friday.
2. Code (green): the rules, `DayScore.jumuahPenalty` and the running total.
3. Check: Linux and macOS CI green, and the today screen's Friday points in a unit test.
