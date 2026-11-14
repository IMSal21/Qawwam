# today screen tasks

Tests first (pushed red), then the code (green). Linux and macOS CI must both pass.

## Task 1: Congregation after logging (core)
- [ ] `PrayerLog.setCongregation(_:for:in:at:)`; throws on a closed day or an unlogged prayer; round-trips through JSON
- Files: `PrayerLog/PrayerLog.swift`, `Tests/.../PrayerLog/CongregationTests.swift`

## Task 2: Today words (core)
- [ ] Durations in both languages: دقيقة واحدة، دقيقتان، 3 دقائق، 11 دقيقة، ساعة، ساعتان، ساعة و49 دقيقة; "1 hr 49 min"
- [ ] The screen's phrases: اليوم، من 5 صلوات، حان وقت العصر، التالي: المغرب، باقي … قبل المغرب، يبدأ … · بعد …، +15 نقطة اليوم، حتى 5:09 م، صلّيت، تراجع، في جماعة، أضف جماعة، صلّيتها في وقتها، أعدها متأخرة، لم تُسجَّل · تُحسب متأخرة، tab names; and English
- Files: `Localization/Words.swift`, `Localization/TodayWords.swift`, tests

## Task 3: TodayState (core)
- [ ] Header, streak, ring, prayed count, hero for due and upcoming and all done, today's points
- [ ] Each row: name (الجمعة on Friday), time, pill, actions (pray, undo, set on time, set late, congregation), unlogged earlier prayer
- [ ] The mockup scene gives exactly the mockup's text
- Files: `Sources/QawwamCore/Today/TodayState.swift`, `Tests/.../Today/TodayStateTests.swift`

## Checkpoint: core done, CI green

## Task 4: TodayStore (app)
- [ ] Loads and saves the log in the App Group file, remembers the first day, re-reads the clock every minute and on returning to the app
- [ ] Log, undo, set timing and congregation update the state and survive a restart
- Files: `App/TodayStore.swift`, `AppTests/TodayStoreTests.swift`

## Task 5: The screen (app)
- [ ] Header, summary card with ring, five rows and tab bar as in the mockup, RTL in Arabic, LTR in English; bundled fonts
- [ ] Farm and Profile tabs show placeholders
- [ ] UI test: tap صلّيت on the due prayer and see في وقتها; screenshots of the mockup scene in both languages
- Files: `App/Today/*.swift`, `App/Fonts/*`, `project.yml`, `AppUITests/*`

## Checkpoint: complete
- [ ] Arabic screenshot matches the mockup; all tests green; PR ready
