# scoring tasks

Each task: tests first (pushed red), then the code (green). Verify with `swift test --package-path QawwamCore` and `swift format lint --recursive --strict` in CI.

## Task 1: Day scores
- [x] Each prayer adds 10 on time or 5 late; all five on time adds the 25 bonus (a perfect day is 75)
- [x] `prayedCount`, `onTimeCount`, `isComplete` and `isClosed` match the log at `now`; undo and switching timing change the day's points
- [x] Days not yet started are left out; days come back oldest first with duplicates dropped
- Files: `Sources/QawwamCore/Scoring/Scoring.swift`, `Tests/QawwamCoreTests/Scoring/DayScoreTests.swift`
- Depends on: none

## Task 2: The streak
- [x] Complete days in a row count back from today; a closed incomplete day resets to 0; best streak keeps the longest run
- [x] Today open and unfinished doesn't break the streak; today complete adds to it at once
- [x] A gap between days (a missing date) breaks the streak
- Files: `Scoring.swift`, `Tests/QawwamCoreTests/Scoring/StreakTests.swift`
- Depends on: 1

## Task 3: The Fajr streak
- [x] Counts days in a row with Fajr on time; a late or missed Fajr resets it; best Fajr streak is kept
- [x] Today before sunrise with no Fajr logged doesn't break it; after sunrise it does; switching to on time restores it
- Files: `Scoring.swift`, `Tests/QawwamCoreTests/Scoring/FajrStreakTests.swift`
- Depends on: 2

## Checkpoint: streaks done
- [x] CI green; every streak rule has a passing test

## Task 4: Streak bonuses, badges and total points
- [x] +50, +100, +150, +300 exactly when a streak reaches 7, 30, 40, 100, and again after a reset
- [x] Badges 3, 7, 30, 40, 100 earned once and kept after a reset
- [x] Total points = all day points + streak bonuses
- Files: `Scoring.swift`, `Tests/QawwamCoreTests/Scoring/MilestoneTests.swift`
- Depends on: 2

## Task 5: Level
- [x] 0 → level 1, 99 → 1, 100 → 2, 299 → 2, 300 → 3, 600 → 4, 1,000 → 5
- Files: `Scoring.swift`, `Tests/QawwamCoreTests/Scoring/LevelTests.swift`
- Depends on: 4

## Task 6: A real Riyadh month
- [x] Riyadh, January 2027: all five every day with one late Isha after midnight and one missed day gives the expected streak, best streak and points; 400 days score in well under a second
- Files: `Tests/QawwamCoreTests/Scoring/ScoringRiyadhTests.swift`
- Depends on: 4, 5

## Checkpoint: complete
- [x] All spec success criteria ticked; CI green; PR ready for Meshari
