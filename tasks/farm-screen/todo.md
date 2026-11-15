# farm screen tasks

Tests first (pushed red), then the code (green). Linux and macOS CI must both pass.

## Task 1: Farm words (core)
- [x] مزرعتي، "25 نخلة"، "15 مثمرة"، "التالي: الفناء بعد 18 يوماً" (with plurals)، the status lines, "فاتت صلاة واحدة / صلاتان / 3 صلوات"، "يوم قادم · لم يبدأ بعد"، "صلّيت العصر"، the hints and legend, the control labels; and the English words
- Files: `Localization/FarmWords.swift`, `Tests/.../Localization/FarmWordsTests.swift`

## Task 2: FarmScreenState (core)
- [x] Header: month, palm and fruit counts for the Hijri month, next building and the days left, hidden after the mosque
- [x] Selected day card: dates, today badge, status and tone for every plot state, five chips, the pray button only while a prayer is due; today is selected by default
- [x] The mockup scene gives exactly the mockup's text
- Files: `Sources/QawwamCore/FarmScreen/FarmScreenState.swift`, `Tests/.../FarmScreen/FarmScreenStateTests.swift`

## Checkpoint: core done, CI green ✓

## Task 3: The 3D scene (app)
- [ ] iOS 18 minimum for the app in `project.yml`
- [ ] `PlaceholderArt` makes a shape for every name in `FarmArt.allNames`; an unknown name gets soil
- [ ] `FarmSceneView`: the island, one plot entity per day, the unlocked buildings, outlines for today, fruit and the selection, drag to turn, pinch to zoom, tap to select
- [ ] App tests: every art name gets a shape; there is one plot entity per day of the month
- Files: `project.yml`, `App/Farm/PlaceholderArt.swift`, `App/Farm/FarmSceneView.swift`, `AppTests/FarmSceneTests.swift`

## Checkpoint: the CI screenshot shows the island

## Task 4: The screen (app)
- [ ] `FarmView`: header pills, the scene card with four buttons and hints, the day card, wired to `TodayStore`; replaces the farm placeholder tab
- [ ] The demo scene grows to the mockup's month
- [ ] UI test: open the farm tab, tap "صلّيت العصر", see "المرحلة 3 من 5"; screenshots `farm-ar` and `farm-en`
- Files: `App/Farm/FarmView.swift`, `App/RootView.swift`, `App/DemoScene.swift`, `AppUITests/ScreenshotTests.swift`, `.github/workflows/ios.yml` (screenshot list)

## Task 5: Growth and accessibility (app)
- [ ] Palms grow in one after another on opening, and today's palm grows when a prayer is logged; no animation with Reduce Motion
- [ ] VoiceOver: the scene is described, each chip reads its name and status, all buttons are labelled
- Files: `App/Farm/FarmSceneView.swift`, `App/Farm/FarmView.swift`

## Checkpoint: complete
- [ ] Arabic screenshot matches the mockup; all tests green; PR ready
