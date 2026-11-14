# cloud-build tasks

Each task is verified in CI on the PR: the Linux core job and the new macOS job must both pass.

## Task 1: App skeleton and macOS build
- [ ] `project.yml` (XcodeGen) with an iPhone app target `Qawwam` (bundle ID `com.qawwam.app`, iOS 17) that depends on the local `QawwamCore` package
- [ ] `App/`: a SwiftUI app with an Arabic-first today screen listing today's five prayer times for Riyadh, using `PrayerTimesCalculator` and `Words`
- [ ] `.github/workflows/ios.yml` on `macos-15`: install XcodeGen, generate, and build for the iOS Simulator without signing
- Files: `project.yml`, `App/QawwamApp.swift`, `App/TodayView.swift`, `.github/workflows/ios.yml`, `.gitignore`
- Depends on: none

## Task 2: App tests
- [ ] `AppTests` target with a test for the today screen's data (five rows, Arabic names, Riyadh times, الجمعة on a Friday)
- [ ] The macOS job runs `xcodebuild test` on an iPhone simulator
- Files: `project.yml`, `App/TodayModel.swift`, `AppTests/TodayModelTests.swift`, `ios.yml`
- Depends on: 1

## Task 3: Screenshots on pull requests
- [ ] `AppUITests` launches the app in Arabic and in English and attaches a screenshot of each main screen
- [ ] The workflow exports the screenshots, pushes them to the `screenshots` branch, and comments them on the PR
- Files: `project.yml`, `AppUITests/ScreenshotTests.swift`, `ios.yml`
- Depends on: 2

## Checkpoint: Meshari checks screenshots from his phone
- [ ] Both jobs green; Arabic and English screenshots visible in the PR comment

## Task 4: Widget extension and App Group
- [ ] Empty widget extension target `QawwamWidgets` (`com.qawwam.app.widgets`) with one placeholder widget
- [ ] App Group `group.com.qawwam.app` declared on both targets
- Files: `project.yml`, `Widgets/QawwamWidgets.swift`, entitlements files
- Depends on: 1

## Task 5 (blocked until the Apple Developer account exists): TestFlight
- [ ] Signed release build with cloud-managed signing and the App Store Connect key from GitHub secrets
- [ ] Upload to TestFlight on merge to main or by hand
- Files: `.github/workflows/testflight.yml`
- Depends on: 1–4 and Meshari's account and secrets
