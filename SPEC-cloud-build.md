# Spec: cloud build (working without a Mac)

Module from [CAPABILITY-MAP.md](CAPABILITY-MAP.md). Comes before `app-shell` and `widgets`.
Status: **draft, waiting for Meshari's approval**

## Assumptions

1. Meshari has no Mac for the next two weeks and wants to stay with Swift (2026-11-11). He tests on his iPhone.
2. All building, signing and uploading runs on **GitHub Actions macOS runners**. The repo is public, so these runners cost nothing.
3. The core logic stays in the `QawwamCore` Swift package and keeps its Linux tests. macOS CI adds the iOS-only parts.
4. The Xcode project is **generated from a text file** (XcodeGen `project.yml`), so it can be written and reviewed without Xcode and never has merge conflicts.
5. Signing uses an **App Store Connect API key** with Xcode's automatic, cloud-managed signing. No certificates or profiles are made by hand, and nothing secret is stored in the repo.
6. Builds reach Meshari's iPhone through **TestFlight**. Simulator screenshots from CI are attached to each pull request so he can see UI changes on his phone before installing.

## Objective

Let the app be built, tested, signed and installed on Meshari's iPhone with nothing but GitHub and his phone, so app-shell and widgets work can start now instead of in two weeks.

## Behaviour

**On every push (free, about 10 minutes):**
- The current Linux job: lint and `swift test` for `QawwamCore`. Unchanged.
- A new macOS job: generate the Xcode project, build the app for the iOS Simulator, and run its UI-side tests.
- On a pull request, take simulator screenshots of the main screens in Arabic and English, and upload them with the run so they can be opened from the phone.

**On a merge to main, or when started by hand:**
- Build a signed release, give it the next build number, and upload it to TestFlight.
- Meshari gets the build in the TestFlight app on his iPhone, usually 10 to 30 minutes later.

**App skeleton (first build only):**
- An iPhone app target `Qawwam` that depends on `QawwamCore`, with a placeholder Arabic today screen showing today's prayer times for Riyadh, so the first TestFlight build proves the whole path end to end.
- A widget extension target and a shared App Group, empty for now, so signing covers them from the start.

## What Meshari needs to do (once, from his phone)

1. **Apple Developer Program**: enrol at developer.apple.com (USD 99 a year) if not already. Approval can take a day or two.
2. **App Store Connect API key**: in App Store Connect, go to Users and Access, Integrations, and create a key with the **Admin** role. Admin is needed for cloud-managed signing.
3. **GitHub secrets**: add the key to the repo under Settings, Secrets and variables, Actions:
   - `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` (the .p8 file's text)
   - `APPLE_TEAM_ID` (from the Membership page)
4. **App record**: create the app in App Store Connect with the bundle ID `com.qawwam.app` (or another he prefers), and add himself as an internal TestFlight tester.
5. Install the **TestFlight** app on his iPhone.

Claude never sees or stores the key. It lives only in GitHub's encrypted secrets.

## Structure

```
project.yml                      # XcodeGen: app, widget extension, App Group, QawwamCore dependency
App/                             # SwiftUI app sources (app-shell)
Widgets/                         # widget extension sources (widgets)
AppTests/  AppUITests/           # tests that need iOS
.github/workflows/core-tests.yml # unchanged
.github/workflows/ios.yml        # macOS: generate, build, test, screenshots
.github/workflows/testflight.yml # macOS: sign, upload on main
```

## Testing Strategy

- The macOS job must pass on every pull request before merge, like the Linux job.
- The first TestFlight build is the end-to-end check: it installs on Meshari's iPhone and shows today's Riyadh times in Arabic.
- Screenshots are checked by Meshari on his phone; anything UI waits for his look before merge.

## Boundaries

- **Always:** keep secrets in GitHub secrets only; keep `QawwamCore` testable on Linux.
- **Ask first:** changing the bundle ID or App Group after the first upload; anything that submits to App Store review (TestFlight internal testing only for now).
- **Never:** commit keys, certificates or profiles; publish to the App Store without Meshari saying so.

## Success Criteria

- [ ] The macOS workflow builds the app and runs its tests on every push.
- [ ] Pull requests carry Arabic and English simulator screenshots.
- [ ] A merge to main puts a new build in TestFlight, and it opens on Meshari's iPhone.

## Open questions for Meshari

1. Do you already have an Apple Developer account, or should you enrol now?
2. Bundle ID: is `com.qawwam.app` fine, or do you have a domain to use (for example `sa.yourname.qawwam`)?
