# prayer-log tasks

Each task: tests first (pushed red), then the code (green). Verify with `swift test --package-path QawwamCore` and `swift format lint --recursive --strict` in CI.

## Task 1: Log types
- [ ] `DayKey` built from a `PrayerDay`, equal for the same date, ordered by date, survives a JSON round trip
- [ ] `PrayerEntry`, `PrayerStatus`, `PrayerLogError` defined as in the spec; an empty `PrayerLog` has no entries
- Files: `Sources/QawwamCore/PrayerLog/PrayerLogTypes.swift`, `Tests/QawwamCoreTests/PrayerLog/PrayerLogTypesTests.swift`
- Depends on: none

## Task 2: Prayer status
- [ ] Every row of the status table: upcoming before start, due from start, prayed(on time / late) once logged, missed at and after next Fajr when not logged
- [ ] Boundaries: exactly at the prayer's start is due; exactly at the next Fajr is missed; a logged prayer stays prayed after the day closes
- [ ] `entry(for:in:)` returns nil when not logged
- Files: `Sources/QawwamCore/PrayerLog/PrayerLog.swift`, `Tests/QawwamCoreTests/PrayerLog/PrayerStatusTests.swift`
- Depends on: 1

## Task 3: Mark a prayer as prayed
- [ ] Inside its window → on time; after its window but before next Fajr → late; the log time and congregation flag are kept
- [ ] Before its start → `notYetDue`; at or after next Fajr → `dayClosed`; nothing is saved when refused
- [ ] Marking an already-logged prayer changes nothing
- Files: `PrayerLog.swift`, `Tests/QawwamCoreTests/PrayerLog/MarkPrayedTests.swift`
- Depends on: 2

## Task 4: Change timing and undo
- [ ] `setTiming` switches late ↔ on time while the day is open; `unmark` removes the entry so the status goes back to due
- [ ] Either one on a prayer that isn't logged → `notLogged`; after the day closes → `dayClosed`
- Files: `PrayerLog.swift`, `Tests/QawwamCoreTests/PrayerLog/EditEntryTests.swift`
- Depends on: 3

## Checkpoint: rules done
- [ ] CI green; every status row and logging rule has a passing test
- [ ] Meshari sees the progress

## Task 6: Save and load the log as a file
- [ ] Save then load gives an identical log, with several days and both timings
- [ ] A missing file loads as an empty log; a corrupt file throws and leaves the file untouched
- [ ] Writes are atomic
- Files: `Sources/QawwamCore/PrayerLog/FilePrayerLogStore.swift`, `Tests/QawwamCoreTests/PrayerLog/FilePrayerLogStoreTests.swift`
- Depends on: 1

## Task 7: Real Riyadh day, Isha after midnight
- [ ] With real Riyadh times, Isha logged at 00:30 the next calendar day lands in the previous prayer day, on time, and the day is still open until Fajr
- Files: `Tests/QawwamCoreTests/PrayerLog/PrayerLogRiyadhTests.swift`
- Depends on: 3

## Checkpoint: complete
- [ ] All spec success criteria ticked; CI green; PR ready for Meshari
