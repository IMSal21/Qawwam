# Spec: localization

Module from [CAPABILITY-MAP.md](CAPABILITY-MAP.md). Depends on: nothing (it names things from `prayer-times`, `prayer-log`, `scoring` and `world`).
Status: **draft, awaiting Meshari's approval**

## Assumptions

1. Arabic is the default language and English is second. The user can switch in settings.
2. This module holds the app's **words and formats**: prayer names, statuses, Hijri and Gregorian dates, times, numbers, and the names of badges and buildings. It is pure Swift in `QawwamCore`, tested on Linux in CI like the other modules.
3. Screen layout, including right-to-left mirroring, is SwiftUI's job in the app (`app-shell`), which needs a Mac. Longer screen text, such as onboarding and settings, goes into the app's string catalog later and builds on the words defined here.
4. Every Arabic word and phrase gets reviewed by a knowledgeable person before launch, as the MVP plan says. This spec proposes the wording; it isn't final.

## Objective

Make the app read naturally in Arabic first: correct prayer names, the Hijri date as the main date, Saudi-style time and number formats, and wording that encourages rather than judges. English should be just as correct for users who switch.

## Behaviour

**Prayer names**

| | Arabic | English |
|---|---|---|
| Fajr | الفجر | Fajr |
| Sunrise | الشروق | Sunrise |
| Dhuhr | الظهر | Dhuhr |
| Asr | العصر | Asr |
| Maghrib | المغرب | Maghrib |
| Isha | العشاء | Isha |

On Fridays Dhuhr is shown as **الجمعة** (Jumu'ah). See question 3.

**Prayer statuses**

| Status | Arabic | English |
|---|---|---|
| upcoming | قادمة | Upcoming |
| due | حان وقتها | Time to pray |
| prayed on time | في وقتها | On time |
| prayed late | قضاء | Late |
| missed | فائتة | Missed |

**Dates**

- The Hijri date is the main date, from the Umm al-Qura calendar: **١٢ رجب ١٤٤٧ هـ** in Arabic, **12 Rajab 1447 AH** in English.
- The Gregorian date is shown small next to it: **١ يناير ٢٠٢٦م** in Arabic, **1 January 2026** in English.
- Hijri month names: محرم، صفر، ربيع الأول، ربيع الآخر، جمادى الأولى، جمادى الآخرة، رجب، شعبان، رمضان، شوال، ذو القعدة، ذو الحجة.
- Weekdays start on Sunday: الأحد … السبت.

**Times:** 12-hour clock with ص and م in Arabic (**٥:٢٠ ص**), and AM and PM in English (**5:20 AM**). Always Asia/Riyadh.

**Numbers:** see question 1. Points, streaks and levels use the same digits as everything else, with plurals handled correctly in Arabic (يوم واحد، يومان، ٣ أيام، ١١ يومًا).

**Badges and buildings**

| Badge | Arabic | Building | Arabic |
|---|---|---|---|
| 3 days | ٣ أيام | Well | البئر |
| 7 days | أسبوع | Farmhouse | البيت النجدي |
| 30 days | شهر | Courtyard | الفناء |
| 40 days | أربعون يومًا | Gate | البوابة |
| 100 days | مئة يوم | Mosque | المسجد |

## Interface (draft)

```swift
public enum AppLanguage: String, CaseIterable, Sendable { case arabic = "ar", english = "en" }

public struct Words: Sendable {
    public init(_ language: AppLanguage)
    public func name(of prayer: Prayer, on day: DayKey) -> String   // الجمعة on Fridays
    public var sunrise: String { get }
    public func status(_ status: PrayerStatus) -> String
    public func hijri(_ date: HijriDate) -> String                  // ١٢ رجب ١٤٤٧ هـ
    public func gregorian(_ day: DayKey) -> String                 // ١ يناير ٢٠٢٦م
    public func weekday(_ day: DayKey) -> String
    public func time(_ instant: Date) -> String                    // ٥:٢٠ ص
    public func number(_ value: Int) -> String
    public func days(_ count: Int) -> String                       // ١١ يومًا
    public func points(_ count: Int) -> String
    public func level(_ level: Int) -> String
    public func badge(_ days: Int) -> String
    public func building(_ building: Building) -> String
}
```

## Commands, structure, style

Same as the other modules: `swift test --package-path QawwamCore`, `swift format lint --recursive --strict`, sources in `Sources/QawwamCore/Localization/`, tests in `Tests/QawwamCoreTests/Localization/`.

## Testing Strategy

- Test-first, with exact expected Arabic and English text for every name, status, month, weekday, badge and building.
- Dates: Hijri and Gregorian for several days, including the first of Ramadan 1448 and a day in Dhu al-Hijjah, checked against the official Riyadh 2027 export.
- Times: Fajr in the morning, Isha at night, midnight and noon, in both languages.
- Arabic plurals for 0, 1, 2, 3, 10, 11, 100 and 101 days.
- Every Arabic string contains no Latin letters, and every English string contains no Arabic letters.

## Boundaries

- **Always:** Arabic first; Umm al-Qura for Hijri dates; Asia/Riyadh for times.
- **Ask first:** changing any religious term (prayer names, قضاء, الجمعة).
- **Never:** build sentences by joining translated fragments in English word order; show Latin digits inside Arabic text if Arabic-Indic digits are chosen.

## Success Criteria

- [ ] Every word and format above has a passing test in both languages.
- [ ] Dates match the official Umm al-Qura calendar.
- [ ] `swift test` and lint pass in CI.

## Open Questions

1. **Digits in Arabic:** Arabic-Indic (**١٢٣**) or Western (**123**)? Proposed: **Arabic-Indic by default, with a setting to switch to Western**. Many Saudi apps use Western digits, so the setting matters.
2. **"Late" in Arabic:** proposed **قضاء**. It's the standard term, but strictly it means making up a prayer after its time. The softer alternative is **متأخرة** ("late").
3. **Friday:** show Dhuhr as **الجمعة** on Fridays? Proposed: **yes**. Its time stays the same as Dhuhr.
