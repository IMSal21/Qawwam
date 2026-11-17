# Spec: onboarding

Third piece of `app-shell` from [CAPABILITY-MAP.md](CAPABILITY-MAP.md). Built from the approved mockups "لماذا قوّام" (OnbWhy), "المدينة" (OnbCity) and "لماذا المزرعة" (OnbFarm) on the [mockups canvas](https://claude.ai/artifact/62Hq1ss3o2dsSs1zjdPDXc).
Depends on: `prayer-times`, `localization`, and the today and farm screens' `TodayStore` (all merged).
Status: **draft, waiting for Meshari's approval**

## Assumptions

1. Onboarding shows **once**, on the first launch, before the tab bar. Finishing it ("ابدأ مزرعتي") saves a "done" flag in the App Group defaults, and from then on the app opens on the today screen.
2. The city decides the prayer times. Today the app is fixed to Riyadh. After this, `TodayStore` uses the chosen city everywhere: today screen, farm, and (later) widgets, which read the same App Group defaults. Every city is in Saudi Arabia, so the time zone stays Asia/Riyadh and the method stays Umm al-Qura.
3. The city list is the mockup's: **26 cities in 13 regions**, each with Arabic and English names and coordinates. It lives in `QawwamCore` so it's tested on Linux.
4. **"استخدم موقعي الحالي"** asks for location once ("while using the app"), then picks the **nearest city on the list** and selects it, so the person sees which city it chose. Only the city is saved, never the exact location, which keeps things private and the times match the city's name on the today screen. If location is refused or fails, a short line says so and the list stays as it is.
5. **Search** matches Arabic or English names, ignoring case, tashkeel, and the usual spelling variants (أ/إ/آ/ا, ة/ه, ى/ي). With no match it shows the mockup's line: "لم نجد هذه المدينة. جرّب اسماً آخر أو استخدم موقعك."
6. **Step 1 answers** (why you came) are multi-choice and saved, but nothing uses them yet. Reminders and challenges will read them later. The mockup shows two options already ticked; in the app **nothing is ticked at first**, so we don't put answers in people's mouths, and "التالي" works with none ticked (the step is optional).
7. On step 2, "التالي" is disabled until a city is chosen. The dark card under the list shows today's five times for the chosen city, worked out by `prayer-times`.
8. Step 3's growth strip is drawn as flat 2D shapes, exactly like the mockup, not with the 3D farm. It's small and doesn't need turning.
9. Back buttons on steps 2 and 3 go back one step and keep what was chosen. Changing the city after onboarding belongs to the profile/settings screen, which gets its own spec.
10. The streak and farm start on the day onboarding finishes, same as today's first-launch rule.
11. Built and checked like the other screens: GitHub's Macs build and test it, and each pull request gets Arabic and English screenshots of all three steps. The screenshot and demo runs skip onboarding unless they ask for it.

## What the screens show (from the mockups)

**Every step:** a progress bar of three segments with "1 من 3", "2 من 3", "3 من 3", read out as "الخطوة 1 من 3". A full-width green button at the bottom.

**Step 1 · لماذا قوّام**
- "أهلاً بك في قوّام" above the title "ما الذي جاء بك إلى قوّام؟".
- "اختر كل ما ينطبق عليك. نستخدم إجابتك لنضبط التذكيرات والتحديات لك."
- Five cards, each with a title, a line under it, and a tick when chosen:
  - أريد أن أصلي الخمس في وقتها · أصلي، لكن أؤخر الصلاة كثيراً
  - أجد صعوبة في المحافظة على الخمس · تفوتني صلاة أو أكثر في بعض الأيام
  - صلاة الفجر صعبة عليّ · أحتاج عوناً على القيام لها في وقتها
  - أريد أن أصلي في جماعة أكثر · خصوصاً الفجر والعشاء
  - أريد أن أرى تقدّمي · سلسلة أيام، ونقاط، ومزرعة تكبر
- Button: "التالي".

**Step 2 · أين تسكن؟**
- "نحسب مواقيت الصلاة لمدينتك بتقويم أم القرى."
- A "استخدم موقعي الحالي" button and a search field "ابحث عن مدينتك".
- Cities grouped under "منطقة …" headings, in the mockup's order:
  - الرياض: الرياض، الخرج، الدرعية، المجمعة
  - القصيم: بريدة، عنيزة، الرس
  - مكة المكرمة: مكة المكرمة، جدة، الطائف
  - المدينة المنورة: المدينة المنورة، ينبع
  - الشرقية: الدمام، الخبر، الأحساء، الجبيل، حفر الباطن
  - عسير: أبها، خميس مشيط
  - تبوك، حائل، الحدود الشمالية (عرعر)، جازان، نجران، الباحة، الجوف (سكاكا): one city each
- The chosen city has a tick. The dark card: "مواقيت اليوم في جدة · أم القرى" with the five times.
- Button: "التالي".

**Step 3 · مزرعتك تكبر مع صلاتك**
- "لماذا مزرعة؟ لأن رؤية أثر التزامك يكبر يوماً بعد يوم تجعل المحافظة أسهل."
- The growth strip, soil to fruiting palm, with 0 to 5 under it and "5 في وقتها" in gold. VoiceOver reads it as one image: "مراحل النخلة: أرض، ثم بذرة، ثم نبتة، ثم فسيلة، ثم نخلة صغيرة، ثم نخلة كاملة مثمرة".
- Four lines with icons:
  - **كل صلاة تسقي نخلة اليوم** فتكبر مرحلة، حتى تكتمل بالصلوات الخمس.
  - **الخمس في وقتها** تجعل النخلة تثمر تمراً.
  - **إن فاتتك صلاة** تذبل نخلة ذلك اليوم، وتبقى في مزرعتك تذكيراً صادقاً.
  - **حافظ على سلسلتك** لتبني بئراً، ثم بيتاً نجدياً، وصولاً إلى المسجد بعد 100 يوم.
- The hadith card: "سُئل النبي ﷺ: أيّ العمل أحبّ إلى الله؟ قال: «الصلاة على وقتها»." with "صحيح البخاري".
- Button: "ابدأ مزرعتي". It saves everything and opens the today screen.

English mirrors all of it left-to-right with English words; the growth strip runs soil to palm left-to-right.

## Interface (draft)

In `QawwamCore` (tested on Linux):

```swift
public struct City: Equatable, Identifiable, Sendable {
    public let id: String            // "jeddah"
    public let region: Region
    public let arabicName, englishName: String
    public let location: GeoPoint
}
public enum SaudiCities {
    public static let all: [City]                          // the 26 cities, mockup order
    public static func city(id: String) -> City?
    public static func search(_ text: String) -> [City]    // normalised Arabic or English
    public static func nearest(to point: GeoPoint) -> City
}
public enum OnboardingReason: String, CaseIterable, Sendable { case onTime, keepFive, fajr, jamaah, progress }
public struct OnboardingSettings: Equatable, Sendable {   // read and written through UserDefaults
    public var isDone: Bool
    public var cityID: String?
    public var reasons: Set<OnboardingReason>
}
public struct OnboardingWords { … }                        // every line above, Arabic and English
```

In the app:

- `OnboardingView`: the three steps, the progress bar and the back button.
- `CityLocator`: a small CoreLocation wrapper that asks once and returns one location or an error.
- `TodayStore` takes the chosen `City` instead of the fixed Riyadh; `RootView` shows onboarding until it's done.
- `Info.plist` gets the location reason: "نستخدم موقعك لنختار أقرب مدينة لحساب مواقيت الصلاة." / "We use your location to pick the nearest city for prayer times."

## Commands, structure, style

Same as the other screens. Core: `swift test --package-path QawwamCore` and `swift format lint --recursive --strict`. App: CI runs `xcodegen` and `xcodebuild test`. App sources go in `App/Onboarding/`, tests in `AppTests/` and `AppUITests/`.

## Testing Strategy

- **Unit tests (test-first)** in `QawwamCore`:
  - the list has 26 cities in 13 regions, in the mockup's order, with unique ids, each inside Saudi Arabia;
  - search: "جده" finds جدة, "الاحساء" finds الأحساء, "riyadh" finds الرياض, "abc" finds nothing, empty text gives the whole list;
  - nearest: a point in Jeddah gives جدة, one near Khamis Mushait gives خميس مشيط;
  - settings save and load, and an unknown city id falls back to "not chosen";
  - every wording above in Arabic and English, and the preview card's title.
- **App tests:** `TodayStore` built with Jeddah gives Jeddah's times and "جدة" on the today screen.
- **UI tests:** a fresh launch shows step 1; going through all three steps with a city picked from search lands on the today screen with that city; a relaunch skips onboarding. Arabic and English screenshots of the three steps go on each pull request. Location isn't tested in CI (the simulator can't grant it without a prompt), only the nearest-city logic.

## Boundaries

- **Always:** match the mockups; keep all wording and city data in `QawwamCore`; save only the city, not the location.
- **Ask first:** adding cities beyond the mockup's 26; using the exact location instead of the nearest city; ticking any answer by default.
- **Never:** send the location or the answers anywhere off the phone; block the app if location is refused.

## Success Criteria

- [ ] The Arabic screenshots match the three onboarding mockups.
- [ ] A new user picks a city and the today screen shows that city's Umm al-Qura times.
- [ ] Onboarding never shows again after it's finished.
- [ ] Unit and UI tests pass in CI on every push.

## Open questions

1. Nearest listed city (assumption 4) versus the exact location. Exact is a minute or two more precise for people far from a listed city, but then the name shown is a guess. I'd start with the nearest city.
2. Untick the mockup's two default answers (assumption 6)?
