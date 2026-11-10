# Tasks: prayer-times

Plan: [plan.md](plan.md). Test command for every task: `swift test --package-path QawwamCore` (run by CI).

## Task 1: Package skeleton and CI

**Description:** Create the `QawwamCore` Swift package depending on Adhan Swift 1.5.0 (exact), with one placeholder test, plus a GitHub Actions workflow that runs `swift test` in the official Swift Docker image on every push and PR.

**Acceptance criteria:**
- [ ] `QawwamCore` builds with Adhan pinned to exactly 1.5.0
- [ ] The workflow runs on push and pull_request and fails when a test fails

**Verification:**
- [ ] CI green on the PR
- [ ] Manual check: a deliberately failing test turns CI red (checked once, not committed)

**Dependencies:** None
**Files likely touched:** `QawwamCore/Package.swift`, `QawwamCore/Sources/QawwamCore/QawwamCore.swift`, `QawwamCore/Tests/QawwamCoreTests/SmokeTests.swift`, `.github/workflows/core-tests.yml`
**Estimated scope:** Small

## Task 2: Prayer and settings types

**Description:** Add `Prayer`, `AsrMadhab`, `PrayerTiming` and `PrayerSettings` with `PrayerSettings.ummAlQura` as the default (standard Asr, no adjustments). Adjustments clamp to −30...+30 minutes.

**Acceptance criteria:**
- [ ] `PrayerSettings.ummAlQura` uses the Umm al-Qura method and standard Asr
- [ ] Hanafi Asr can be set; adjustments outside −30...+30 are clamped
- [ ] Types are `Codable`, `Equatable`, `Sendable`

**Verification:**
- [ ] Tests written first and pass in CI

**Dependencies:** Task 1
**Files likely touched:** `Sources/QawwamCore/PrayerTimes/Prayer.swift`, `Sources/QawwamCore/PrayerTimes/PrayerSettings.swift`, `Tests/QawwamCoreTests/PrayerTimes/PrayerSettingsTests.swift`
**Estimated scope:** Small

## Task 3: Daily times with Ramadan Isha

**Description:** `PrayerTimesCalculator.day(_:at:in:)` returns a `PrayerDay` with the five times, sunrise and the next day's Fajr, using Adhan. In Ramadan (Umm al-Qura Hijri calendar) Isha is Maghrib + 120 minutes.

**Acceptance criteria:**
- [ ] Riyadh times for one known date are within 1 minute of the official calendar
- [ ] On a Ramadan date, Isha equals Maghrib + 120 minutes
- [ ] Per-prayer adjustments shift the matching time by exactly that many minutes

**Verification:**
- [ ] Tests written first and pass in CI

**Dependencies:** Task 2
**Files likely touched:** `Sources/QawwamCore/PrayerTimes/PrayerDay.swift`, `Sources/QawwamCore/PrayerTimes/PrayerTimesCalculator.swift`, `Tests/QawwamCoreTests/PrayerTimes/PrayerTimesCalculatorTests.swift`
**Estimated scope:** Medium

## Checkpoint: Foundation
- [ ] CI green
- [ ] Review with Meshari

## Task 4: Prayer windows and on time / late

**Description:** `PrayerDay.window(for:)` and `PrayerDay.timing(of:loggedAt:)` following the window table in the spec.

**Acceptance criteria:**
- [ ] Each window opens and closes as in the spec table (start inclusive, end exclusive)
- [ ] Logged exactly at the start counts as on time; exactly at the end counts as late
- [ ] Isha's window runs to the next day's Fajr

**Verification:**
- [ ] Tests written first and pass in CI

**Dependencies:** Task 3
**Files likely touched:** `Sources/QawwamCore/PrayerTimes/PrayerDay.swift`, `Tests/QawwamCoreTests/PrayerTimes/PrayerWindowTests.swift`
**Estimated scope:** Small

## Task 5: Prayer day containing any instant

**Description:** `PrayerTimesCalculator.prayerDay(containing:at:in:)` returns the prayer day (Fajr to next Fajr) an instant belongs to.

**Acceptance criteria:**
- [ ] 1:00 AM belongs to the previous day's prayer day
- [ ] Exactly at Fajr starts the new prayer day

**Verification:**
- [ ] Tests written first and pass in CI

**Dependencies:** Task 4
**Files likely touched:** `Sources/QawwamCore/PrayerTimes/PrayerTimesCalculator.swift`, `Tests/QawwamCoreTests/PrayerTimes/PrayerDayLookupTests.swift`
**Estimated scope:** Small

## Task 6: Golden fixtures for 13 regions × 4 dates

**Description:** JSON fixtures of official Umm al-Qura times for Riyadh, Makkah, Madinah, Dammam, Buraydah, Abha, Tabuk, Hail, Arar, Jazan, Najran, Al-Bahah and Sakaka on both solstices, an equinox and a Ramadan day, each with its source, plus a test that checks all 52 within 1 minute.

**Acceptance criteria:**
- [ ] 52 city-date fixtures, each citing where it came from
- [ ] Golden test passes within 1 minute for every prayer in every fixture

**Verification:**
- [ ] CI green
- [ ] Manual check: spot-check 3 fixtures against the official site

**Dependencies:** Task 3; reference data from ummulqura.org.sa (see plan risks)
**Files likely touched:** `Tests/QawwamCoreTests/Fixtures/prayer-times/*.json`, `Tests/QawwamCoreTests/PrayerTimes/GoldenTimesTests.swift`, `Package.swift` (test resources)
**Estimated scope:** Medium

## Task 7: Edge cases and lint in CI

**Description:** Tests for the northernmost and southernmost points of the Kingdom and adjustment edges, and `swift format lint --strict` added to CI.

**Acceptance criteria:**
- [ ] Edge-case tests pass
- [ ] CI fails on a lint violation

**Verification:**
- [ ] CI green

**Dependencies:** Tasks 4 to 6
**Files likely touched:** `Tests/QawwamCoreTests/PrayerTimes/EdgeCaseTests.swift`, `.github/workflows/core-tests.yml`
**Estimated scope:** Small

## Checkpoint: Complete
- [ ] All spec success criteria met
- [ ] Review with Meshari before the next module
