# Implementation Plan: prayer-times

Spec: [SPEC-prayer-times.md](../SPEC-prayer-times.md) (approved 2026-11-10)
Status: **draft, awaiting Meshari's approval**

## Overview

Build the `prayer-times` module inside a new local Swift package, `QawwamCore`: Umm al-Qura times for any place in Saudi Arabia, each prayer's on-time window, and the on time / late judgement. Pure logic, tested on Linux, no UI.

## Architecture Decisions

- **Adhan Swift 1.5.0, pinned exactly.** Its only import is Foundation, so it builds on Linux. Its `ummAlQura` method is Fajr 18.5° with Isha 90 minutes after Maghrib, and its docs say to add 30 minutes to Isha in Ramadan. We do that ourselves, giving Maghrib + 120 as the spec requires.
- **Tests run in GitHub Actions on Linux** inside the official `swift` Docker image, on every push and PR. The repo is public, so Actions minutes are free. No Mac is needed until the app and widget modules.
- **Swift isn't installed locally.** The cloud environment blocks download.swift.org, so CI is where tests run. I push a branch, read the CI result, and fix until it's green.
- **Time zone is always Asia/Riyadh** for now, passed in explicitly rather than read from the device.
- **One small PR per task**, each with its tests, so every change is easy to review.

## Task List

### Phase 1: Foundation

- [ ] Task 1: Package skeleton and CI
- [ ] Task 2: Prayer and settings types
- [ ] Task 3: Daily times with Ramadan Isha

### Checkpoint: Foundation
- [ ] CI green on Linux
- [ ] Riyadh times for one date match Umm al-Qura within 1 minute

### Phase 2: Windows and judging

- [ ] Task 4: Prayer windows and on time / late
- [ ] Task 5: Prayer day containing any instant (after-midnight Isha)

### Phase 3: Proof against the official calendar

- [ ] Task 6: Golden fixtures for 13 regions × 4 dates
- [ ] Task 7: Edge cases and lint in CI

### Checkpoint: Complete
- [ ] All 52 golden checks pass within 1 minute
- [ ] Every success criterion in the spec is ticked
- [ ] Review with Meshari before moving to `localization` and `prayer-log`

Task details, acceptance criteria and verification are in [todo.md](todo.md).

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| The official Umm al-Qura site (ummulqura.org.sa) is blocked from the cloud environment, so I can't fetch reference times myself | High: blocks Task 6 | Meshari allows that domain in the environment's network settings, or sends the timetable pages; Tasks 1 to 5 don't wait for it |
| Adhan's Umm al-Qura differs from the official calendar by more than 1 minute in some city | Medium | Golden tests surface it; fix with documented per-prayer adjustments, never by loosening the tolerance |
| Hijri month boundary for Ramadan differs from the announced moon sighting by a day | Low | Use `Calendar(identifier: .islamicUmmAlQura)`, the official Saudi calendar; revisit if users report it |
| CI round-trips are slower than local tests | Low | Keep tasks small so each push is one focused check |

## Open Questions

- Can you allow `ummulqura.org.sa` in the environment's network settings so I can fetch the official reference times? I'll send the exact steps.
