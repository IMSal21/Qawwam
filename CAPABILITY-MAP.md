# Capability Map: Qawwam iOS MVP

Source plan: [Qawwam iOS MVP Plan](https://claude.ai/artifact/KB1KMBxgz9Ai58yt47cjs5)
Status: **approved by Meshari, 2026-11-10** (spec-driven-development, Phase 0)

The MVP bundles several capabilities that can be built and tested on their own, so each
module below gets its own spec (`SPEC-<module-id>.md`) once this map is approved.

## Assumptions

1. Native iOS app in SwiftUI, minimum iOS 17, dependencies through Swift Package Manager.
2. No backend and no account in the MVP. All data stays on the device (a JSON file in an App Group container shared with widgets, see SPEC-prayer-log.md).
3. The world is a **farm**, possibly with Islamic building styles (Meshari, 2026-11-10). `world` still keeps the theme as swappable art plus names.
4. Prayer times are in the MVP only to judge "on time" vs "late". Notifications come in v1.1.
5. Arabic is the default language with right-to-left layout; English is secondary.
6. Point values and streak rules are the ones in the plan doc (all five prayed keeps the streak, late counts, a missed day resets to zero, no exemptions).
7. Pure logic (`prayer-times`, `prayer-log`, `scoring`, `world` state) lives in a local Swift package, `QawwamCore`, so it can be unit tested without the UI.

## Modules (MVP)

| Module id | Responsibility | Depends on |
|---|---|---|
| prayer-times | Daily times and on-time windows from location, method, madhab (Adhan Swift) | — |
| localization | Arabic-first strings, RTL layout, Arabic prayer names, Hijri date, number formatting | — |
| prayer-log | One state per prayer per day (on time, late, missed, blank), day closes at next Fajr, persistence | prayer-times |
| scoring | Points, streak, Fajr streak, milestone badges, level; pure rules over the log | prayer-log |
| world | Turns each day's log into garden state (tree stage 0 to 5, blossom, wilted) and renders it from layered images | prayer-log, scoring |
| app-shell | Onboarding, location or city picker, settings, today screen, history, profile | prayer-times, localization, prayer-log, scoring, world |
| widgets | Small, medium, large and lock screen widgets; "Prayed" App Intent | prayer-log, scoring, world |

Build order: prayer-times, localization → prayer-log → scoring → world → app-shell → widgets

## Later modules (not specified yet)

| Module id | Release | Depends on |
|---|---|---|
| reminders | v1.1 | prayer-times |
| live-activity | v1.1 | prayer-log, prayer-times |
| fajr-alarm | v1.2 | prayer-times, prayer-log, scoring |
| shop | v1.2 | scoring, world |

## Verification constraint

iOS code can only be built and tested on macOS with Xcode. The cloud environment where Claude
works is Linux with no Swift toolchain, so every module's tests need one of:

- a GitHub Actions macOS runner running `xcodebuild test` on each push (chosen: Meshari has no Mac for now; the repo is public so runners are free; see SPEC-cloud-build.md), or
- a Remote Control session on Meshari's Mac.

## Open questions

- Art source: illustrator, asset pack, or AI drafts cleaned up by a designer?
