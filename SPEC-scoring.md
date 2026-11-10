# Spec: scoring

Module from [CAPABILITY-MAP.md](CAPABILITY-MAP.md). Depends on: `prayer-log` (and `prayer-times` for `PrayerDay`).
Status: **draft, awaiting Meshari's approval**

## Assumptions

1. Pure Swift inside `QawwamCore`, tested on Linux in CI like the other modules. No UI.
2. Nothing is stored. Points, streaks, level and badges are worked out from the prayer log every time, so undo and "I prayed it on time" always give the right totals.
3. The current time is passed in and never read from the clock.
4. The caller passes every prayer day from the user's first day (the day they started using Qawwam) up to the day containing now. Days before the first day don't count against the user.
5. The point values and streak rules are the ones in the [MVP plan](https://claude.ai/artifact/KB1KMBxgz9Ai58yt47cjs5), approved earlier.

## Objective

Give the user a score that rewards praying all five on time without punishing late prayers too hard, and a streak that is strict: all five prayed (on time or late) every day, a missed day resets it to zero, and there are no exemptions. The app's profile, the farm and the widgets all read their numbers from here.

## Rules

**Points**

| Event | Points |
|---|---|
| Prayer logged on time | 10 |
| Prayer logged late | 5 |
| All five on time in one day | +25 bonus |
| Streak reaches 7, 30, 40, 100 days | +50, +100, +150, +300 bonus |
| Missed prayer | 0, and the streak resets |

- Points for a prayer count as soon as it's logged, even while the day is still open. Undo removes them, and switching late to on time adds the difference.
- The all-five-on-time bonus is added as soon as the fifth prayer is logged on time.

**Streak**

- A day is **complete** when all five prayers are prayed, on time or late.
- The streak is the number of complete days in a row, counting back from today.
- Today never breaks the streak while it's still open. It adds to the streak as soon as it's complete.
- A closed day that isn't complete (any prayer missed) resets the streak to zero. A day the user never opened the app also counts as missed.
- The best streak ever is also kept, for the profile.

**Fajr streak:** a separate, harder streak. It counts days in a row with Fajr prayed **on time** (before sunrise). Today's Fajr doesn't break it until sunrise passes without an on-time log, and switching it to on time later the same day restores it. See open question 2.

**Level:** worked out from total points. See open question 3.

**Badges:** earned once, the first time the streak reaches 3, 7, 30, 40 and 100 days. A badge stays even after the streak resets.

## Interface (draft)

```swift
public struct ScoringRules: Sendable {
    public static let standard: ScoringRules   // the table above
}

public struct DayScore: Equatable, Sendable {
    public let day: DayKey
    public let points: Int            // prayers plus the all-on-time bonus
    public let prayedCount: Int       // 0...5
    public let onTimeCount: Int       // 0...5
    public let isComplete: Bool       // all five prayed
    public let isClosed: Bool         // the next Fajr has begun
}

public struct Score: Equatable, Sendable {
    public let totalPoints: Int       // day points plus streak bonuses
    public let level: Int
    public let currentStreak: Int
    public let bestStreak: Int
    public let currentFajrStreak: Int
    public let bestFajrStreak: Int
    public let badges: [Int]          // streak lengths reached: 3, 7, 30, 40, 100
    public let days: [DayScore]       // oldest first, for history and the weekly view
}

public enum Scoring {
    public static func score(_ log: PrayerLog, days: [PrayerDay], at now: Date,
                             rules: ScoringRules = .standard) -> Score
}
```

## Commands, structure, style

Same as the other modules: `swift test --package-path QawwamCore`, `swift format lint --recursive --strict`, sources in `Sources/QawwamCore/Scoring/`, tests in `Tests/QawwamCoreTests/Scoring/`.

## Testing Strategy

- Unit tests on hand-built prayer days and logs, test-first: every row of the points table, the all-on-time bonus appearing and disappearing with undo and timing changes, and each streak rule.
- Streak edge cases: an open day that isn't finished yet, a missed day in the middle, a gap of days with no logs at all, an Isha logged after midnight.
- Milestones: each streak bonus and badge exactly at 3, 7, 30, 40 and 100 days, not one day early.
- One longer test over a real Riyadh month using `prayer-times`.

## Boundaries

- **Always:** work everything out from the log; pass time in.
- **Ask first:** changing any point value or streak rule.
- **Never:** store totals separately from the log; add an exemption or streak freeze.

## Success Criteria

- [ ] Every rule above has a passing test.
- [ ] Undo and timing changes always give the same totals as if the log had been that way from the start.
- [ ] `swift test` and lint pass in CI.

## Open Questions

1. **Streak bonus after a reset:** if the streak resets and later reaches 7 again, is the +50 earned again? Proposed: **yes**, every time a streak reaches 7, 30, 40 or 100, so coming back is rewarded. Badges are still earned only once.
2. **Fajr streak:** does Fajr need to be on time (before sunrise) to count? Proposed: **yes, on time only**. That's what makes it the harder streak.
3. **Level:** proposed **level 2 at 100 points, and each next level needs 100 more than the last** (level 3 at 300, level 4 at 600, level 5 at 1,000). A perfect day earns 75, so early levels come within days and later ones take weeks.
