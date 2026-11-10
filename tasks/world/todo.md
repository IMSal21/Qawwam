# world tasks

Each task: tests first (pushed red), then the code (green). Verify with `swift test --package-path QawwamCore` and `swift format lint --recursive --strict` in CI.

## Task 1: A plot's stage, state and art name
- [x] Stage is the number of prayers prayed (0 to 5), in any order, on time or late
- [x] States: growing (open, under five), grown (five, one or more late), fruiting (five on time), wilted (closed, under five)
- [x] Art names: `soil`, `palm.stage1`…`palm.stage5`, `palm.stage5.fruit`, `palm.stage<N>.wilted`; undo and timing changes update the plot
- Files: `Sources/QawwamCore/World/Plot.swift`, `Tests/QawwamCoreTests/World/PlotTests.swift`
- Depends on: none

## Task 2: Today's ring
- [x] Five segments, Fajr first: on time, late, due, upcoming or missed, matching the log at `now`
- Files: `Sources/QawwamCore/World/Farm.swift`, `Tests/QawwamCoreTests/World/RingTests.swift`
- Depends on: 1

## Task 3: The week
- [x] Seven plots from Sunday to Saturday around the given day; today is marked
- [x] Days after today are `future`, days before the first day are `unused`
- Files: `Farm.swift`, `Tests/QawwamCoreTests/World/WeekTests.swift`
- Depends on: 1

## Checkpoint: today and week done
- [x] CI green; every stage and state has a passing test

## Task 4: The Hijri month
- [x] Every day of the Umm al-Qura month containing the given day, in order, each with its Hijri and Gregorian date and a farm position (row = week of the month, column = weekday), for the 3D scene
- [x] Month starts and lengths match the official Riyadh 2027 export; Ramadan 1448 is one month
- Files: `Farm.swift`, `Sources/QawwamCore/World/HijriDate.swift`, `Tests/QawwamCoreTests/World/MonthTests.swift`
- Depends on: 3

## Task 5: Buildings from badges
- [x] Well at 3 days, farmhouse at 7, courtyard at 30, gate at 40, mosque at 100, in unlock order, kept after a reset
- Files: `Sources/QawwamCore/World/Building.swift`, `Tests/QawwamCoreTests/World/BuildingTests.swift`
- Depends on: none

## Task 6: The whole farm, the art list and a real Riyadh month
- [x] `FarmBuilder.farm` puts today, ring, week, month and buildings together
- [x] `Plot.allArtNames` lists every art name a plot can produce, with no extras
- [x] A real Riyadh month (Ramadan 1448) gives the expected plots and buildings
- Files: `Farm.swift`, `Tests/QawwamCoreTests/World/FarmTests.swift`
- Depends on: 2, 3, 4, 5

## Checkpoint: complete
- [x] All spec success criteria ticked; CI green; PR ready for Meshari
