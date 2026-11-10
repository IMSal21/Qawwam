# Spec: world

Module from [CAPABILITY-MAP.md](CAPABILITY-MAP.md). Depends on: `prayer-log`, `scoring` (and `prayer-times` for `PrayerDay`).
Status: **draft, awaiting Meshari's approval**

## Assumptions

1. The world is a **farm**, possibly with Islamic building styles (Meshari, 2026-11-10).
2. This module is the farm's **logic only**: what every plot and building should look like. It returns plain values and art names. Drawing them with SwiftUI happens in the app and widgets, which need a Mac. The logic is pure Swift in `QawwamCore`, tested on Linux in CI like the other modules.
3. Nothing is stored. The farm is worked out from the prayer log and the score every time, so it always matches them.
4. The art isn't drawn yet. Art names are stable keys (for example `palm.stage3`), so placeholder images can be swapped for the final art without code changes.
5. The week starts on Sunday, as in Saudi Arabia.

## Objective

Make every logged prayer visibly grow something, the way Forest grows a tree while you focus. Each prayer day gets one plot on the farm. Prayers grow that day's plant one stage at a time, a perfect day bears fruit, and a missed day wilts and stays as an honest record. The farm screen and the widgets show the result.

## Behaviour

**One plot per prayer day**, with one plant growing in five stages:

| Prayed so far | Stage | Looks like (proposed: a date palm, see question 1) |
|---|---|---|
| 0 | empty | Bare soil, ready to plant |
| 1 | stage 1 | Seed planted |
| 2 | stage 2 | Sprout |
| 3 | stage 3 | Sapling |
| 4 | stage 4 | Young palm |
| 5 | stage 5 | Full palm |

The stage is the number of prayers prayed that day, on time or late, in any order. Logging an earlier prayer late still grows the plant.

**Plot states**

| State | When |
|---|---|
| growing | Today, still open, fewer than five prayed |
| grown | All five prayed, at least one late |
| fruiting | All five prayed on time: the palm carries dates |
| wilted | The day closed with a prayer missed. The plant stays at its stage, wilted |
| future | A day that hasn't started yet (empty plots in the week and month views) |

Undo and "I prayed it on time" change the plot straight away, because everything is worked out from the log.

**Views the app and widgets need**

- **Today:** today's plot, its stage and state, and how many prayers are left.
- **Week:** seven plots from Sunday to Saturday, today marked, plus the current streak (medium widget).
- **Month:** every day of the month as a plot, in calendar order (large widget and the farm screen). See question 2.
- **Ring:** five segments for today, each prayed on time, prayed late, due, upcoming or missed (lock screen widget and the today screen).

**Buildings (proposed, see question 3):** the badges from scoring unlock buildings in Islamic styles that stay on the farm for good:

| Badge | Building |
|---|---|
| 3 days | A well |
| 7 days | A mud-brick farmhouse (Najdi style) |
| 30 days | A palm-shaded courtyard with a fountain |
| 40 days | Arched gate and walls |
| 100 days | A small mosque with a minaret |

## Interface (draft)

```swift
public enum PlotState: Equatable, Sendable { case growing, grown, fruiting, wilted, future }

public struct Plot: Equatable, Sendable {
    public let day: DayKey
    public let stage: Int             // 0...5
    public let state: PlotState
    public let isToday: Bool
    public var artName: String        // e.g. "palm.stage3", "palm.stage5.fruit", "palm.stage2.wilted", "soil"
}

public enum RingSegment: Equatable, Sendable { case onTime, late, due, upcoming, missed }

public enum Building: String, CaseIterable, Sendable { case well, farmhouse, courtyard, gate, mosque }

public struct Farm: Equatable, Sendable {
    public let today: Plot?
    public let ring: [RingSegment]                      // five, Fajr first
    public func week(containing day: DayKey) -> [Plot]  // Sunday to Saturday
    public func month(containing day: DayKey) -> [Plot]
    public let buildings: [Building]                    // in the order unlocked
}

public enum FarmBuilder {
    public static func farm(_ log: PrayerLog, days: [PrayerDay], at now: Date) -> Farm
}
```

## Commands, structure, style

Same as the other modules: `swift test --package-path QawwamCore`, `swift format lint --recursive --strict`, sources in `Sources/QawwamCore/World/`, tests in `Tests/QawwamCoreTests/World/`.

## Testing Strategy

- Unit tests on hand-built days and logs, test-first: every row of the stage and state tables, and undo and timing changes.
- Week and month layout: Sunday start, today marked, future days, a month that starts mid-week, and months of 29, 30 and 31 days.
- Buildings: each one unlocks exactly at its badge and stays after the streak resets.
- Every art name a plot can produce is in one list, so the artist knows exactly which images to draw.

## Boundaries

- **Always:** work everything out from the log and score; keep art names stable once released.
- **Ask first:** changing what a stage or state means; renaming art.
- **Never:** remove a wilted plot (it stays as a record); draw or load images in this module.

## Success Criteria

- [ ] Every stage, state, ring segment and building rule has a passing test.
- [ ] The full list of art names is generated from the code and matches what plots can produce.
- [ ] `swift test` and lint pass in CI.

## Open Questions

1. **The plant:** proposed **a date palm** (نخلة), with dates as the fruit on a perfect day. It fits a Saudi farm. Alternatives: wheat, an olive tree, or a mix of crops.
2. **Month view:** proposed **the Hijri month** (Umm al-Qura), so Ramadan is one whole farm, with the Gregorian date shown small. The alternative is the Gregorian month.
3. **Buildings from badges:** proposed **yes**, using the table above. They give the farm Islamic architecture and make the badges visible. The alternative is to keep buildings for the v1.2 shop.
