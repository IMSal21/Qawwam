# Plan: today screen

From [SPEC-today-screen.md](../../SPEC-today-screen.md), approved 2026-11-15.

## Approach

- All wording and numbers are worked out in `QawwamCore`, test-first on Linux, where tests are fast. The app only lays them out.
- Two small core additions the screen needs: turning congregation on or off after logging, and Arabic and English durations ("ساعة و49 دقيقة").
- The app keeps the log in the App Group folder and remembers the user's first day, so scoring knows where to start.
- The screen copies the mockup's layout, colors and fonts. Fonts (IBM Plex Sans Arabic, Reem Kufi, both SIL OFL) are committed with their license.
- UI tests launch the app at a fixed time with a fixed log, the mockup's scene: Tuesday 10 Nov 2026, 3:20 PM, Fajr on time in congregation, Dhuhr late, Asr due. The PR screenshots are therefore comparable with the mockup.

## Order and risks

1. Core first, because the screen depends on it and Linux CI is quick.
2. App store and persistence next, with tests on the simulator.
3. Views last, checked against the mockup through screenshots. Risk: fonts not loading; the screenshot shows it at once.

## Checkpoints

- After task 3: Linux and macOS jobs green.
- After task 5: Meshari compares the Arabic screenshot with the mockup.
