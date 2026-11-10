# Implementation Plan: localization

## Overview

Build the words and formats from [SPEC-localization.md](../../SPEC-localization.md): `Words(language)` gives every prayer name, status, date, time, number, badge and building name in Arabic (the default) or English. Pure Swift in `QawwamCore`, tested on Linux in CI, written test-first (tests pushed red, then the code green).

## Architecture Decisions

- **Hand-written tables, not system locales.** Foundation's Arabic locale writes Arabic-Indic digits and varies between Apple and Linux. Meshari chose Western digits, so names come from fixed tables in the code and numbers are formatted by hand. The output is then identical on every device and in CI.
- **Arabic plurals follow the standard six forms** (zero, one, two, few for 3–10, many for 11–99, other for 100–102 and so on, by the last two digits). One helper serves days and points.
- **Hijri dates come from `HijriDate`** (the world module), which already matches the official Umm al-Qura calendar on every day of 2027.
- **Times are in Asia/Riyadh**, 12-hour, with ص and م in Arabic and AM and PM in English.
- **Jumu'ah scoring is separate.** Meshari's request for extra Jumu'ah points and deductions changes the scoring module, so it goes through the scoring spec, not this plan. This module only names the prayer.

## Task List

See [todo.md](todo.md).

1. Prayer names, Jumu'ah on Fridays, and statuses (S)
2. Numbers and Arabic plurals for days, points and levels (S)
3. Hijri and Gregorian dates and weekdays (S)
   - Checkpoint: names, numbers and dates done
4. Times (XS)
5. Badges and buildings (XS)
6. Script check over every string (XS)
   - Checkpoint: complete

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Wrong Arabic plural form | Med: looks careless | Tests for 0, 1, 2, 3, 10, 11, 99, 100, 101, 102, 103 and 111 |
| A religious term reads wrong | High: trust | Wording is reviewed by a knowledgeable person before launch, as the plan says |
| Midnight or noon shown wrongly in 12-hour time | Low | Tests for 00:00, 00:30, 12:00 and 12:30 |

## Open Questions

None. Meshari answered all three spec questions on 2026-11-10.
