# Implementation Plan: prayer-log

## Overview

Build the prayer log from [SPEC-prayer-log.md](../../SPEC-prayer-log.md): the record of which prayers the user logged each prayer day, the status of each prayer (upcoming, due, prayed on time or late, missed), the logging rules, and saving the log to a JSON file. Pure Swift in `QawwamCore`, tested on Linux in CI, written test-first.

This plan sits in `tasks/prayer-log/` so it doesn't replace `tasks/plan.md`, which still holds the unfinished prayer-times Task 6 (golden times for the other 12 regions).

## Architecture Decisions

- **One prayer day = one key.** Entries are stored by `DayKey` (the Gregorian date the prayer day starts on, taken from `PrayerDay.date`) and then by `Prayer`. `PrayerLog` is a plain `Codable` value, so saving is just encoding it.
- **Rules take a `PrayerDay` and a `now`.** The log never computes prayer times and never reads the clock. Tests use hand-built `PrayerDay` values with round times, so the rules are tested apart from astronomy.
- **Missed is derived, not stored.** Not logged and `now >= nextFajr` means missed.
- **Logging an already-logged prayer changes nothing.** The spec doesn't say; a second tap from a widget or notification shouldn't move the original log time or flip its timing. Use `setTiming` or `unmark` to change it.
- **The file store writes atomically** (`Data.write(options: .atomic)`) and pretty-prints with sorted keys, so the file is stable and readable. A file that can't be decoded throws instead of loading as empty, so history is never silently wiped.

## Task List

See [todo.md](todo.md).

1. Log types (S)
2. Prayer status (S)
3. Mark a prayer as prayed (S)
4. Change timing and undo (S)
   - Checkpoint: rules done
5. Save and load the log as a file (S)
6. Real Riyadh day, Isha after midnight (XS)
   - Checkpoint: complete

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Boundary off by one (exactly at a prayer's start or at the next Fajr) | High: wrong streak | A test at each exact boundary instant; start inclusive, end exclusive, as in prayer-times |
| `DateComponents` as a key encodes inconsistently | Med | `DayKey` stores plain year, month and day integers, with its own tests |
| File format changes after release break saved history | High later | Format is fixed by tests now; changing it after release is an ask-first item in the spec |
| Two writers (app and widget) at the same time | Low for MVP | Only the app writes in the MVP; the widget only reads. Revisit with the Live Activity in v1.1 |

## Open Questions

None. All four spec questions were answered by Meshari on 2026-11-10.
