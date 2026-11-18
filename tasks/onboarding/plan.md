# Plan: onboarding

From [SPEC-onboarding.md](../../SPEC-onboarding.md), approved 2026-11-18.

## Approach

- **Core first, test-first on Linux.** `SaudiCities` (the 26 cities, search and nearest), `OnboardingSettings` (saved in the App Group defaults) and `OnboardingWords` (every line on the three steps) live in `QawwamCore`. The app only lays them out.
- **The city flows through one place.** `TodayStore` takes a `City` instead of the fixed Riyadh, so the today screen, the farm and later the widgets all follow it. Riyadh stays the fallback if nothing is saved.
- **Onboarding sits in front of the tabs.** `RootView` shows `OnboardingView` until `isDone` is true. "ابدأ مزرعتي" saves the city, the answers and the flag, then the tabs appear.
- **Location is a thin wrapper.** `CityLocator` asks once for one location and hands it to `SaudiCities.nearest`. The exact point is never saved.
- **Screenshots and demo skip onboarding.** A launch argument (`-onboarding`) opens it on a fresh state for its own UI tests and screenshots; the existing farm and today screenshots are unchanged.

## Order and risks

1. City data and search (task 1), because the rest depends on it. Risk: Arabic spelling variants in search. The tests list the variants from the spec.
2. Settings and words (task 2).
3. `TodayStore` follows the city (task 3). Risk: breaking the today and farm screens. Their existing tests and screenshots guard it.
4. The three screens and the flow (task 4), then location (task 5). Location can't be granted in CI, so only the nearest-city logic is tested there; the prompt waits for a real phone.

## Checkpoints

- After task 2: Linux and macOS jobs green.
- After task 3: today and farm screenshots unchanged.
- After task 5: Meshari compares the three Arabic screenshots with the mockups.
