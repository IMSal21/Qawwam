# Plan: farm screen

From [SPEC-farm-screen.md](../../SPEC-farm-screen.md), approved 2026-11-15.

## Approach

- **Core first, test-first on Linux.** `FarmScreenState` works out every word and count on the screen: header pills, next building, the selected day's card, its chips and the pray button. The app only lays them out and draws.
- **The 3D scene is a thin layer.** `PlaceholderArt` turns each art name from `world` into a small low-poly RealityKit entity. `FarmSceneView` places one per plot and building at the plot's row and column, and turns taps into a selected day. It decides nothing about how a plot looks.
- **One shared store.** The farm reads the same `TodayStore` as the today screen, so logging on either screen updates both.
- **The minimum goes to iOS 18** in `project.yml` and the `QawwamCore` package, for RealityKit's non-AR view and orbit camera.
- **A fuller demo scene.** The mockup's month: the user started on 4 Jumada al-Ula, day 17 has Maghrib and Isha missed, the mockup's 15 days are fruiting and the rest are complete with one prayer late. The today screen's scene stays the same: a streak of 12, with Fajr on time and Dhuhr late today.

## Order and risks

1. Core state and wording (tasks 1 to 2), because everything depends on them and Linux CI is quick.
2. iOS 18 and the scene (task 3). **Highest risk:** RealityKit rendering in the CI simulator and in screenshots. It comes early, so a problem shows up before the rest is built. The fallback is SceneKit with the same `PlaceholderArt` names.
3. The screen and its UI tests (task 4), then polish: growth animation, Reduce Motion and VoiceOver labels (task 5).

## Checkpoints

- After task 2: Linux and macOS jobs green.
- After task 3: the CI screenshot shows the 3D island with palms.
- After task 5: Meshari compares the Arabic screenshot with the mockup.
