# localization tasks

Each task: tests first (pushed red), then the code (green). Verify with `swift test --package-path QawwamCore` and `swift format lint --recursive --strict` in CI.

## Task 1: Prayer names, Jumu'ah and statuses
- [ ] All six names (five prayers and sunrise) in Arabic and English
- [ ] Dhuhr is الجمعة / Jumu'ah on Fridays and Dhuhr on every other day
- [ ] The five statuses: قادمة، حان وقتها، في وقتها، متأخرة، فائتة, and their English names
- Files: `Sources/QawwamCore/Localization/Words.swift`, `Tests/QawwamCoreTests/Localization/PrayerWordsTests.swift`
- Depends on: none

## Task 2: Numbers and plurals
- [ ] Western digits in both languages
- [ ] Arabic days: يوم واحد، يومان، 3 أيام، 11 يومًا، 100 يوم, by the six plural forms; English: 1 day, 2 days
- [ ] Points and levels in both languages
- Files: `Words.swift`, `Sources/QawwamCore/Localization/ArabicPlural.swift`, `Tests/QawwamCoreTests/Localization/NumberWordsTests.swift`
- Depends on: none

## Task 3: Dates and weekdays
- [ ] Hijri: 12 رجب 1447 هـ / 12 Rajab 1447 AH, with all twelve month names, matching the official Riyadh 2027 export
- [ ] Gregorian: 1 يناير 2026م / 1 January 2026; weekdays الأحد to السبت and Sunday to Saturday
- Files: `Words.swift`, `Tests/QawwamCoreTests/Localization/DateWordsTests.swift`
- Depends on: none

## Checkpoint: names, numbers and dates done
- [ ] CI green

## Task 4: Times
- [ ] 5:20 ص / 5:20 AM, 7:45 م / 7:45 PM, midnight 12:00 ص, noon 12:00 م, always Asia/Riyadh
- Files: `Words.swift`, `Tests/QawwamCoreTests/Localization/TimeWordsTests.swift`
- Depends on: none

## Task 5: Badges and buildings
- [ ] The five badge names and five building names in both languages
- Files: `Words.swift`, `Tests/QawwamCoreTests/Localization/FarmWordsTests.swift`
- Depends on: none

## Task 6: Script check
- [ ] No Latin letters in any Arabic string, no Arabic letters in any English string, Western digits only
- Files: `Tests/QawwamCoreTests/Localization/ScriptTests.swift`
- Depends on: 1–5

## Checkpoint: complete
- [ ] All spec success criteria ticked; CI green; PR ready for Meshari
