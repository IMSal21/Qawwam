# Spec: today screen

First piece of `app-shell` from [CAPABILITY-MAP.md](CAPABILITY-MAP.md). Built from the approved mockup ("اليوم · Today" on the [mockups canvas](https://claude.ai/artifact/62Hq1ss3o2dsSs1zjdPDXc)).
Depends on: `prayer-times`, `prayer-log`, `scoring`, `world`, `localization` (all merged).
Status: **approved by Meshari, 2026-11-15**

## Assumptions

1. This replaces the test screen from the cloud build work. It looks like the mockup, not like a plain list.
2. The city is fixed to **Riyadh** until onboarding (city picker) is built next. Onboarding is its own spec.
3. The log is saved on the phone in the App Group container (`group.com.qawwam.app`), as the prayer-log spec says, so widgets can read it later.
4. Fonts are the ones in the mockup: **IBM Plex Sans Arabic** for text and **Reem Kufi** for headings. Both are free (SIL Open Font License) and are bundled in the app.
5. Western digits everywhere (decision from localization). The mockup's colors are used as-is: ground #F3F1EA, surface white, ink #15302A, palm green #1E6B4E, gold #9A6A12, late #8A5300, missed #9B3B2C.
6. Built and checked the same way as the skeleton: GitHub's Macs build and test it, and every pull request gets Arabic and English screenshots. The UI tests use a fixed time and log so the screenshots always show the same scene as the mockup (Tuesday afternoon, Fajr on time, Dhuhr late, Asr due).

## What the screen shows (from the mockup, top to bottom)

**Header**
- "اليوم" as the title.
- The weekday and Hijri date: الثلاثاء 30 جمادى الأولى 1448.
- The Gregorian date and city, small: 10 نوفمبر 2026 · الرياض.
- A streak pill with a flame: "12 يوماً" (current streak from scoring).

**Summary card**
- A ring with five segments, Fajr first: green on time, amber late, light green due, grey upcoming, red missed (from `FarmBuilder.ring`).
- In the middle, how many are prayed: "2 من 5 صلوات".
- Beside it, the current state: "حان وقت العصر" with the time left, or "التالي: المغرب" with when it starts.
- Today's points with a star: "+15 نقطة اليوم".

**Five prayer rows**
- The name (الجمعة on Fridays) and its time.
- A status pill: في وقتها, متأخرة, حان وقتها · حتى 5:09 م, قادمة, فائتة.
- **Due:** a big صلّيت button and an "في جماعة" checkbox.
- **Prayed:** a تراجع (undo) button and a congregation toggle. A late prayer offers "صلّيتها في وقتها". A prayer logged late and switched to on time offers "أعدها متأخرة".
- **Upcoming:** "يبدأ 5:09 م".
- **An earlier prayer that wasn't logged while due:** the row says "لم تُسجَّل · تُحسب متأخرة", and logging it counts as late.

**Tab bar:** اليوم, المزرعة, ملفي. Farm and Profile open placeholder screens for now; they get their own specs.

**Live updates:** the screen updates every minute and when the app comes back to the front, so a prayer turns due on time and the countdown stays right.

English mirrors all of it left-to-right, using the English words from localization.

## Interface (draft)

`TodayState` is pure logic, so it lives in `QawwamCore` (`Sources/QawwamCore/Today/`) and is tested on Linux with the other modules. Only `TodayStore` and the views live in the app.

```swift
/// Everything the today screen shows, worked out from the log and the time. No UI.
struct TodayState: Equatable {
    struct Row: Equatable { prayer, name, time, status: PrayerStatus, pill, actions: Set<RowAction>, inCongregation }
    let title, dateLine, gregorianLine, streakText: String
    let ring: [RingSegment]
    let prayedText, heroTitle, heroSubtitle, pointsText: String
    let rows: [Row]
    init(log: PrayerLog, days: [PrayerDay], words: Words, now: Date)
}

@Observable final class TodayStore {      // loads and saves the log, re-reads the clock
    func markPrayed(_ prayer: Prayer, inCongregation: Bool)
    func undo(_ prayer: Prayer)
    func setTiming(_ timing: PrayerTiming, for prayer: Prayer)
    func setCongregation(_ on: Bool, for prayer: Prayer)
}
```

All the screen's wording and numbers come from `TodayState`, so they're unit-tested. The SwiftUI views only lay it out.

## Testing Strategy

- **Unit tests (test-first)** on `TodayState` with hand-built days and logs: every pill and action, the ring, the hero text for due and upcoming, points, streak, الجمعة on Friday, and the unlogged earlier prayer that counts as late.
- **Store tests:** log, undo and switching timing save to the file and survive a restart.
- **UI tests:** tap صلّيت on the due prayer and see it turn to في وقتها. Screenshots in Arabic and English of the mockup scene go on each pull request.

## Boundaries

- **Always:** all numbers from the core modules; time passed in so tests are fixed; match the mockup.
- **Ask first:** any change to the mockup's layout or wording.
- **Never:** store totals separately from the log.

## Success Criteria

- [ ] The Arabic screenshot matches the mockup's today screen. (waiting for Meshari's look)
- [x] Logging, undo, late or on time, and congregation all work and are saved.
- [x] Unit and UI tests pass in CI on every push.

## Open questions

None. City picker and onboarding come next in their own spec.
