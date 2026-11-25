# onboarding tasks

Tests first (pushed red), then the code (green). Linux and macOS CI must both pass.

## Task 1: Saudi cities (core)
- [x] 26 cities in 13 regions in the mockup's order, unique ids, Arabic and English names, coordinates inside Saudi Arabia
- [x] Search ignores case, tashkeel, أ/إ/آ/ا, ة/ه and ى/ي: "جده" finds جدة, "الاحساء" finds الأحساء, "riyadh" finds الرياض, "abc" finds nothing, empty text gives all
- [x] Nearest: a point in Jeddah gives جدة, one near Khamis Mushait gives خميس مشيط
- Files: `Sources/QawwamCore/Onboarding/SaudiCities.swift`, `Tests/.../Onboarding/SaudiCitiesTests.swift`

## Task 2: Settings and words (core)
- [x] `OnboardingSettings` saves and loads done, city and answers through UserDefaults; an unknown city id reads as not chosen
- [x] `OnboardingWords`: every line of the three steps, "1 من 3", the region headings, the empty search line, "مواقيت اليوم في جدة · أم القرى", the location error line; and English
- Files: `Sources/QawwamCore/Onboarding/OnboardingSettings.swift`, `Localization/OnboardingWords.swift`, matching tests

## Checkpoint: core done, CI green ✓

## Task 3: The app follows the city (app)
- [x] `TodayStore` takes a `City`; times, the today title and the farm use it; Riyadh if none is saved
- [x] App test: a store with Jeddah gives Jeddah's times and "جدة"
- Files: `App/TodayStore.swift`, `App/QawwamApp.swift`, `App/DemoScene.swift`, `AppTests/TodayStoreCityTests.swift`

## Checkpoint: today and farm screenshots unchanged ✓

## Task 4: The three steps (app)
- [x] `OnboardingView`: progress bar, back button, step 1 cards (none ticked, Next always on), step 2 search, region list, tick and times card (Next off until a city is chosen), step 3 strip, lines and hadith card
- [x] `RootView` shows onboarding until done; "ابدأ مزرعتي" saves and opens the today screen
- [x] UI tests: a fresh launch shows step 1; search "جدة", pick it, finish, and the today screen shows جدة; a relaunch skips onboarding; screenshots `onb-why`, `onb-city`, `onb-farm` in Arabic and English
- Files: `App/Onboarding/OnboardingView.swift`, `App/Onboarding/GrowthStrip.swift`, `App/RootView.swift`, `AppUITests/OnboardingTests.swift`, `.github/workflows/ios.yml`

## Task 5: Use my location (app)
- [x] `CityLocator` asks once (the permission prompt waits for a real phone), gets one location, picks the nearest city; refused or failed shows the error line and keeps the list
- [x] Info.plist location reason in Arabic and English
- Files: `App/Onboarding/CityLocator.swift`, `project.yml`

## Checkpoint: complete
- [ ] Arabic screenshots match the mockups (waiting for Meshari's look)
- [x] All tests green; PR ready
