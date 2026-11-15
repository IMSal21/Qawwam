# Spec: farm screen

Second piece of `app-shell` from [CAPABILITY-MAP.md](CAPABILITY-MAP.md). Built from the approved mockup ("المزرعة · Farm" on the [mockups canvas](https://claude.ai/artifact/62Hq1ss3o2dsSs1zjdPDXc)).
Depends on: `world`, `scoring`, `prayer-log`, `localization`, and the today screen's `TodayStore` (all merged).
Status: **approved by Meshari, 2026-11-15**

## Assumptions

1. The farm is **3D and interactive**, as Meshari asked (2026-11-10): you can turn it, zoom it and tap a day. It uses Apple's **RealityKit**. Apple stopped developing SceneKit in 2025, so we start on the engine that has a future.
2. RealityKit's non-AR 3D view needs **iOS 18**, so the app's minimum goes from iOS 17 to iOS 18. Most iPhones in use run iOS 18 or later by late 2026.
3. The palms, soil and buildings are **simple low-poly shapes made in code**, the same style as the mockup. Each one is keyed by its art name from `world` (`palm.stage3`, `building.well` and so on). Real 3D models can replace them later without changing any logic.
4. The farm shows the **current Hijri month**, one plot per day, laid out like a calendar page (Sunday first), as `world` already works out. Browsing earlier months comes later.
5. The mockup's "إعادة" button and its "للتجربة" note were only there to try the mockup out, so they are left out. The "صلّيت" button on today's card stays and logs the prayer that is due, exactly like the today screen. When no prayer is due, there's no button.
6. Built and checked the same way as the today screen: GitHub's Macs build and test it, and every pull request gets Arabic and English screenshots. The screenshot scene is the mockup's: Jumada al-Ula 1448, the user started on day 4, day 17 wilted, today is day 30 with Fajr on time and Dhuhr late. The today screen's streak of 12 stays the same.

## What the screen shows (from the mockup, top to bottom)

**Header**
- "مزرعتي" as the title, with the Hijri month and year: جمادى الأولى 1448.
- Three pills:
  - Complete palms this month: "25 نخلة".
  - Fruiting palms: "15 مثمرة" (gold).
  - The next building: "التالي: الفناء بعد 18 يوماً". The days are the streak days still needed. Once every building is unlocked, this pill is hidden.

**The 3D farm** (a rounded card, 380 points high)
- A sand-coloured island with one soil plot per day of the month.
- Each plot shows its art: bare soil, dry soil, palm stages 1 to 5, a fruiting palm with date bunches, or a wilted palm that leans and droops.
- Days before the user started are pale soil. Today's plot has a green outline, fruiting plots have a gold frame, and the selected plot has a bright gold outline.
- Unlocked buildings stand behind the plots: the well (3 days), the Najdi farmhouse (7), the courtyard (30), the gate and walls (40) and the mosque (100). There are also two decorative palms.
- **Controls:**
  - Drag to turn the farm and tilt the view, within limits.
  - Pinch to zoom.
  - Four buttons, each 44 points: turn left, turn right, zoom in, zoom out.
  - Tap a plot to select its day.
- Hints in the corner: "اسحب للتدوير · اضغط على يوم", and the fruit legend "مثمرة: عذوق تمر وإطار ذهبي".
- **Growth:** when the screen opens, the palms grow in one after another. When a prayer is logged, today's palm grows to its new stage. With Reduce Motion on, there's no animation.

**Selected day card** (today is selected when the screen opens)
- The Hijri date ("30 جمادى الأولى"), an "اليوم" badge on today, and the Gregorian date shown small ("10 نوفمبر 2026").
- The status line, in the plot's colour:
  - Before the user started: "قبل بدايتك · أرض فارغة"
  - Growing: "نبتة تنمو · المرحلة 2 من 5"
  - Grown: "نخلة كاملة · صلّيت الخمس"
  - Fruiting: "نخلة مثمرة · الخمس في وقتها"
  - Wilted: "ذابلة · فاتت صلاتان" (with the right count: صلاة واحدة, صلاتان, 3 صلوات)
  - A day still to come: "يوم قادم · لم يبدأ بعد". This is new; the mockup has no future day.
- Five prayer chips coloured by status: on time, late, missed, due (outlined) and upcoming. Each one reads out its name and status for VoiceOver.
- On today, while a prayer is due: "صلّيت العصر" logs it.

**Tab bar:** المزرعة is selected. The tab bar is shared with the today screen.

**Live updates:** the farm uses the same store and clock as the today screen. A prayer logged on either screen shows on the other straight away.

English mirrors all of it left-to-right with the English words. The 3D farm itself doesn't flip.

## Interface (draft)

All wording, counts and the selected day's details are worked out in `QawwamCore` (`Sources/QawwamCore/FarmScreen/`) and tested on Linux. Only the 3D scene and the views live in the app.

```swift
/// Everything the farm screen shows apart from the 3D shapes. No UI.
public struct FarmScreenState: Equatable {
    public struct DayCard: Equatable { hijriText, gregorianText, isToday, statusText, tone: PlotTone,
                                       chips: [PrayerChip], prayButtonText: String? }
    public let title, monthText, palmsText, fruitText: String
    public let nextBuildingText: String?
    public let plots: [Plot]              // from Farm.month(containing:)
    public let buildings: [Building]
    public let selected: DayCard
    public init(log: PrayerLog, days: [PrayerDay], words: Words, now: Date, selected: DayKey?)
}
```

In the app:

- `FarmView`: the header, the card with the scene, the controls and the day card.
- `FarmSceneView`: a RealityKit `RealityView`. It builds one entity per plot and building, and handles camera turning, zooming and tapping.
- `PlaceholderArt`: makes the low-poly shape for each art name. It throws no errors: an unknown name gets plain soil.

## Commands, structure, style

Same as the today screen. Core: `swift test --package-path QawwamCore` and `swift format lint --recursive --strict`. App: CI runs `xcodegen` and `xcodebuild test`. App sources go in `App/Farm/` and tests in `AppTests/` and `AppUITests/`.

## Testing Strategy

- **Unit tests (test-first)** on `FarmScreenState`, with hand-built days and logs:
  - the header counts and the next building's days, and its absence once the mosque is unlocked;
  - every status line and the wilted count wording;
  - the chips;
  - the pray button only while a prayer is due;
  - selecting another day;
  - the mockup scene giving exactly the mockup's text.
- **App tests:** `PlaceholderArt` returns a shape for every name in `FarmArt.allNames`, and the scene has one plot entity per day of the month.
- **UI tests:** open the farm tab, tap "صلّيت العصر", and see the status turn to "المرحلة 3 من 5". Arabic and English screenshots of the mockup scene go on each pull request.

## Boundaries

- **Always:** take all numbers and states from the core modules; pass the time in so tests are fixed; match the mockup.
- **Ask first:** any change to the mockup's layout or wording beyond what's listed here; replacing the placeholder shapes with outside 3D models.
- **Never:** store farm state separately from the log; let the 3D scene decide what a plot looks like.

## Success Criteria

- [ ] The Arabic screenshot matches the mockup's farm screen. (waiting for Meshari's look)
- [ ] Turning, zooming and tapping a day work on the phone, and logging from the farm updates both screens. (logging is covered by UI tests; the gestures wait for a phone)
- [x] Unit and UI tests pass in CI on every push.

## Open questions

None, unless Meshari disagrees with an assumption above. The most likely one to revisit is iOS 18 as the minimum (2).
