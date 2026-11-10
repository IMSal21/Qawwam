# Spec: prayer-times

Module from [CAPABILITY-MAP.md](CAPABILITY-MAP.md). Depends on: nothing.
Status: **draft, awaiting Meshari's approval**

## Assumptions

1. This module is pure Swift logic inside the `QawwamCore` package: no UI, no CoreLocation, no network. Callers pass in coordinates, a time zone and settings.
2. Calculation uses the [Adhan Swift](https://github.com/batoulapps/adhan-swift) library, pinned to an exact release (version picked and checked against its docs before the first commit).
3. The time zone comes from the chosen location, not the device, so a manually picked city in another zone shows that city's times.
4. "On time" means logged within the prayer's window; anything after the window closes but before the day closes is "late".

## Objective

Give the rest of the app one reliable answer to two questions: *when is each prayer today?* and *was this prayer prayed on time?* Everything in Qawwam that judges a prayer (points, streak, the tree's growth) depends on these answers, so they must match what people see at their local mosque.

**User-facing outcomes**

- A user in Riyadh sees the same times as the Umm al-Qura calendar, within 1 minute.
- A user anywhere gets a sensible calculation method by default, based on their country, and can change it.
- A user can nudge any prayer by whole minutes to match their mosque.
- Logging Asr at 4:10 PM when Asr is 3:20 PM and Maghrib is 5:30 PM counts as on time; logging it at 6:00 PM counts as late.

## Behaviour

**Prayer windows** (start inclusive, end exclusive):

| Prayer | Window opens | Window closes |
|---|---|---|
| Fajr | Fajr | Sunrise |
| Dhuhr | Dhuhr | Asr |
| Asr | Asr | Maghrib |
| Maghrib | Maghrib | Isha |
| Isha | Isha | Next day's Fajr |

**Prayer day:** runs from one Fajr to the next. A prayer logged after midnight but before Fajr belongs to the previous day. The day "closes" at the next Fajr; `prayer-log` uses this to turn blanks into missed.

**Default calculation method by country** (ISO code from the location):

| Country | Method |
|---|---|
| SA | Umm al-Qura |
| AE | Dubai |
| KW | Kuwait |
| QA | Qatar |
| EG | Egyptian |
| PK, IN, BD | Karachi |
| TR | Turkey (Diyanet) |
| SG, MY, ID | Singapore |
| US, CA | North America (ISNA) |
| anything else | Muslim World League |

**Other settings**

- Asr madhab: Shafi'i, Maliki, Hanbali (default) or Hanafi.
- High-latitude rule: Adhan's recommended rule for the coordinates, unless the user overrides it.
- Per-prayer adjustments: whole minutes, −30 to +30.
- Umm al-Qura in Ramadan: Isha is Maghrib + 120 minutes (Ramadan detected with `Calendar(identifier: .islamicUmmAlQura)`).

## Interface (draft)

```swift
public enum Prayer: Int, CaseIterable, Codable, Sendable {
    case fajr, dhuhr, asr, maghrib, isha
}

public struct PrayerSettings: Codable, Equatable, Sendable {
    public var method: CalculationMethodID
    public var madhab: AsrMadhab
    public var highLatitudeRule: HighLatitudeRuleID?   // nil = recommended for location
    public var adjustments: [Prayer: Int]              // minutes, -30...30

    public static func defaults(forCountry code: String?) -> PrayerSettings
}

public struct PrayerDay: Equatable, Sendable {
    public let date: DateComponents          // the Gregorian day this prayer day starts on
    public let times: [Prayer: Date]
    public let sunrise: Date
    public let nextFajr: Date

    public func window(for prayer: Prayer) -> DateInterval
    public func timing(of prayer: Prayer, loggedAt: Date) -> PrayerTiming   // .onTime or .late
}

public struct PrayerTimesCalculator: Sendable {
    public init(settings: PrayerSettings)
    public func day(_ date: DateComponents, at coordinates: Coordinates, in timeZone: TimeZone) throws -> PrayerDay
    public func prayerDay(containing instant: Date, at coordinates: Coordinates, in timeZone: TimeZone) throws -> PrayerDay
}
```

## Tech Stack

- Swift 6, Swift Package Manager
- Adhan Swift (exact version pinned)
- Swift Testing for tests

## Commands

```
Test:   swift test --package-path QawwamCore
Lint:   swift format lint --recursive --strict QawwamCore
Format: swift format --in-place --recursive QawwamCore
```

These run on macOS, and on Linux if Adhan Swift builds there (checked during the first task).

## Project Structure

```
QawwamCore/
  Package.swift
  Sources/QawwamCore/PrayerTimes/      → Prayer, PrayerSettings, PrayerDay, PrayerTimesCalculator
  Tests/QawwamCoreTests/PrayerTimes/   → unit and golden-file tests
  Tests/QawwamCoreTests/Fixtures/prayer-times/  → reference timetables as JSON
```

## Code Style

```swift
/// Returns whether a prayer logged at `loggedAt` falls inside its window.
public func timing(of prayer: Prayer, loggedAt: Date) -> PrayerTiming {
    window(for: prayer).contains(loggedAt) ? .onTime : .late
}
```

- Value types, no singletons, no hidden clock: the current time is always a parameter.
- Names in English in code; user-facing text never lives in this module.
- `swift format` defaults, 4-space indent.

## Testing Strategy

- **Golden-file tests:** reference times for 6 places × 4 dates (both solstices, an equinox, a day in Ramadan), stored as JSON fixtures. Places: Riyadh, Makkah, Dubai, Cairo, London, Oslo. Every computed time must be within 1 minute of the reference.
- **Unit tests:** window boundaries (exactly at start counts as on time, exactly at end counts as late), the after-midnight Isha case, adjustments, Ramadan Isha, country defaults, daylight-saving days in London.
- **Coverage:** every public function has tests; aim for 90%+ line coverage on this module.
- Tests fail first, then pass (test-driven-development).

## Boundaries

- **Always:** keep the module free of I/O and the system clock; run tests and lint before every commit; record the source of every fixture.
- **Ask first:** adding any dependency besides Adhan Swift; changing a country default; changing the window rules.
- **Never:** call the network from this module; commit failing or skipped tests; loosen the 1-minute tolerance to make a test pass.

## Success Criteria

- [ ] All golden-file tests pass within 1 minute for all 24 place-date pairs.
- [ ] Window and timing rules behave exactly as in the table above, boundaries included.
- [ ] Country defaults return the methods listed.
- [ ] `swift test` and `swift format lint` pass.

## Open Questions

1. Should Hanafi be the default Asr madhab for Pakistan, India, Bangladesh and Turkey? (Proposed: yes.)
2. Reference source for the fixtures: published timetables (Umm al-Qura calendar, mosque timetables) or the Aladhan API? (Proposed: official timetables where they exist, Aladhan for the rest.)
3. Where tests run: GitHub Actions macOS runner, installing Swift on the Linux cloud environment for this pure-logic module, or your Mac.
