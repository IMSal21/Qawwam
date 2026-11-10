# Spec: prayer-log

Module from [CAPABILITY-MAP.md](CAPABILITY-MAP.md). Depends on: `prayer-times`.
Status: **draft, awaiting Meshari's approval**

## Assumptions

1. Pure Swift inside `QawwamCore`, tested on Linux like `prayer-times`. No UI.
2. The current time is always passed in, never read from the clock, so every rule is testable.
3. The log is saved as a small JSON file. In the app, that file lives in the shared App Group folder so widgets can read it. This replaces SwiftData from the first plan, because SwiftData only runs on Apple devices and couldn't be tested here (see open question 4).
4. A "day" is a prayer day from `prayer-times`: Fajr to the next Fajr.

## Objective

Remember, for every prayer of every day, whether the user prayed it, and if so whether on time or late. Everything else in Qawwam (points, the streak, how the day's tree grows, the widget) reads from this log, so its rules must be simple and strict.

**User-facing outcomes**

- Tapping "Prayed" on Asr at 4:10 PM, when Asr is 3:20 PM to 5:30 PM, records Asr as **on time**.
- Tapping "Prayed" on Asr at 6:00 PM records it as **late**.
- Tapping "Prayed" on Isha at 1:00 AM counts for the previous evening's Isha.
- A prayer nobody logged becomes **missed** the moment the next Fajr begins.
- Once the next Fajr begins, that day is final and can't be changed.

## Behaviour

**Status of a prayer** at a given moment:

| Status | When |
|---|---|
| upcoming | Its time hasn't started yet |
| due | Its time has started, it isn't logged, and the day is still open |
| prayed (on time / late) | The user logged it |
| missed | Not logged, and the day has closed (the next Fajr has begun) |

"Missed" is worked out from the time, not stored, so nothing has to run at Fajr for it to happen.

**Logging rules**

- **Mark prayed:** allowed once the prayer's time has started and until the day closes. On time or late is decided automatically from the moment it's logged (the windows in `SPEC-prayer-times.md`).
- **"I prayed it on time":** while the day is open, the user can change a late entry to on time, for when they prayed in time but logged it later. They can also change it back.
- **Congregation:** each entry can be marked "in congregation" (for the Fajr-in-congregation badge later).
- **Undo:** while the day is open, a logged prayer can be un-logged.
- **Too early:** logging a prayer before its time starts is refused.
- **Day closed:** any change after the next Fajr is refused.

## Interface (draft)

```swift
public struct DayKey: Hashable, Comparable, Codable, Sendable   // e.g. 2026-11-10, from PrayerDay.date

public struct PrayerEntry: Codable, Equatable, Sendable {
    public var timing: PrayerTiming          // .onTime or .late
    public let loggedAt: Date
    public var inCongregation: Bool
}

public enum PrayerStatus: Equatable, Sendable {
    case upcoming, due, prayed(PrayerTiming), missed
}

public enum PrayerLogError: Error, Equatable {
    case notYetDue, dayClosed, notLogged
}

public struct PrayerLog: Codable, Equatable, Sendable {
    public func status(of prayer: Prayer, in day: PrayerDay, at now: Date) -> PrayerStatus
    public func entry(for prayer: Prayer, in day: PrayerDay) -> PrayerEntry?

    public mutating func markPrayed(_ prayer: Prayer, in day: PrayerDay, at now: Date, inCongregation: Bool = false) throws
    public mutating func setTiming(_ timing: PrayerTiming, for prayer: Prayer, in day: PrayerDay, at now: Date) throws
    public mutating func unmark(_ prayer: Prayer, in day: PrayerDay, at now: Date) throws
}

public protocol PrayerLogStore: Sendable {
    func load() throws -> PrayerLog          // an empty log if nothing is saved yet
    func save(_ log: PrayerLog) throws
}

public struct FilePrayerLogStore: PrayerLogStore {
    public init(fileURL: URL)                // atomic writes
}
```

## Commands, structure, style

Same as `SPEC-prayer-times.md`: `swift test --package-path QawwamCore`, `swift format lint --strict`, sources in `Sources/QawwamCore/PrayerLog/`, tests in `Tests/QawwamCoreTests/PrayerLog/`.

## Testing Strategy

- Unit tests on a hand-built `PrayerDay`, so the rules are tested apart from astronomy: every row of the status table, every logging rule, and each boundary (exactly at the prayer's start, exactly at the next Fajr).
- One test using real Riyadh times for the after-midnight Isha case.
- File store: save then load gives the same log, a missing file loads as empty, and a corrupt file throws instead of silently wiping history.
- Test-first, as before.

## Boundaries

- **Always:** pass time in; keep history intact (never drop entries on load or save).
- **Ask first:** changing what "missed" or "day closed" means; changing the file format once the app is released.
- **Never:** let a closed day change; read the system clock inside this module.

## Success Criteria

- [ ] Every row of the status table and every logging rule has a passing test.
- [ ] Saved logs load back identically; corrupt files raise an error.
- [ ] `swift test` and lint pass in CI.

## Open Questions

1. **What happens if a prayer is logged after its own time ends?** Meshari (2026-11-10): the user needs to log before the prayer time ends, since logging will be a quick notification or widget tap. Still to settle on the decision card: does a log after its time count as **late** (fewer points, streak survives) or as **missed** (streak resets)? Either way a closed day can't be fixed.

## Decisions

2. **"I prayed it on time" changes:** yes, while the day is open (honour system). Meshari, 2026-11-10.
3. **Congregation flag in the MVP:** yes. Meshari, 2026-11-10.
4. **JSON file instead of SwiftData:** yes. Meshari left the choice to us on 2026-11-10; a JSON file is simpler, testable on Linux, and readable by widgets.
