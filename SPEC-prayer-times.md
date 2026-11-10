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
- Every user gets Umm al-Qura times by default, and can change the method in settings if they live abroad.
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

**Calculation method:** Umm al-Qura for every user, since Qawwam is a Saudi app built on Saudi-approved sources. Other methods stay available in settings for users abroad, but nothing is picked by country.

**Other settings**

- Asr: the standard (majority) shadow rule, as used by Umm al-Qura. The later Hanafi Asr is an optional setting, off by default.
- High-latitude rule: Adhan's recommended rule for the coordinates, applied automatically (only matters for users far north, not in Saudi Arabia).
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

    public static let ummAlQura: PrayerSettings   // the default
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

These run in the Linux cloud environment (Swift toolchain installed there), so no Mac is needed for this module. App and widget modules will need a macOS CI runner later.

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

- **Golden-file tests:** reference times from the official Umm al-Qura calendar for 6 Saudi cities × 4 dates (both solstices, an equinox, a day in Ramadan), stored as JSON fixtures with their source. Cities: Riyadh, Makkah, Madinah, Dammam, Abha, Tabuk. Every computed time must be within 1 minute of the reference.
- **Unit tests:** window boundaries (exactly at start counts as on time, exactly at end counts as late), the after-midnight Isha case, adjustments, Ramadan Isha, the Umm al-Qura default, a non-Saudi location with a manually chosen method.
- **Coverage:** every public function has tests; aim for 90%+ line coverage on this module.
- Tests fail first, then pass (test-driven-development).

## Boundaries

- **Always:** keep the module free of I/O and the system clock; run tests and lint before every commit; record the source of every fixture.
- **Ask first:** adding any dependency besides Adhan Swift; changing the default method; changing the window rules.
- **Never:** call the network from this module; commit failing or skipped tests; loosen the 1-minute tolerance to make a test pass.

## Success Criteria

- [ ] All golden-file tests pass within 1 minute for all 24 city-date pairs.
- [ ] Window and timing rules behave exactly as in the table above, boundaries included.
- [ ] The default settings are Umm al-Qura with standard Asr.
- [ ] `swift test` and `swift format lint` pass.

## Decisions

- 2026-11-10, Meshari: Umm al-Qura is the default for everyone; Saudi-approved sources only; tests run on Linux, since no Mac is available.
