import Foundation
import Testing

@testable import QawwamCore

private typealias F = ScoringFixtures

@Suite struct FajrStreakTests {
    @Test func fajrOnTimeOnDaysInARowMakesTheFajrStreak() {
        var log = PrayerLog()
        for index in 0..<4 {
            F.pray(.fajr, on: index, in: &log)
        }

        let score = Scoring.score(log, days: F.days(4), at: F.at(3, 12))

        #expect(score.currentFajrStreak == 4)
        #expect(score.bestFajrStreak == 4)
    }

    @Test func theFajrStreakOnlyNeedsFajrNotAllFive() {
        var log = PrayerLog()
        F.pray(.fajr, on: 0, in: &log)
        F.pray(.fajr, on: 1, in: &log)

        let score = Scoring.score(log, days: F.days(2), at: F.at(2, 5, 0))

        #expect(score.currentFajrStreak == 2)
        #expect(score.currentStreak == 0)
    }

    @Test func aLateFajrResetsTheFajrStreak() {
        var log = PrayerLog()
        F.pray(.fajr, on: 0, in: &log)
        F.pray(.fajr, on: 1, in: &log)
        F.pray(.fajr, on: 2, .late, in: &log)

        let score = Scoring.score(log, days: F.days(3), at: F.at(2, 12))

        #expect(score.currentFajrStreak == 0)
        #expect(score.bestFajrStreak == 2)
    }

    @Test func aMissedFajrResetsTheFajrStreak() {
        var log = PrayerLog()
        F.pray(.fajr, on: 0, in: &log)
        F.pray(.fajr, on: 2, in: &log)

        let score = Scoring.score(log, days: F.days(3), at: F.at(2, 12))

        #expect(score.currentFajrStreak == 1)
        #expect(score.bestFajrStreak == 1)
    }

    @Test func beforeSunriseTodaysUnloggedFajrDoesNotBreakIt() {
        var log = PrayerLog()
        F.pray(.fajr, on: 0, in: &log)
        F.pray(.fajr, on: 1, in: &log)

        let score = Scoring.score(log, days: F.days(3), at: F.at(2, 6, 39))

        #expect(score.currentFajrStreak == 2)
    }

    @Test func atSunriseTodaysUnloggedFajrBreaksIt() {
        var log = PrayerLog()
        F.pray(.fajr, on: 0, in: &log)
        F.pray(.fajr, on: 1, in: &log)

        let score = Scoring.score(log, days: F.days(3), at: F.at(2, 6, 40))

        #expect(score.currentFajrStreak == 0)
        #expect(score.bestFajrStreak == 2)
    }

    @Test func switchingTodaysFajrToOnTimeRestoresIt() {
        var log = PrayerLog()
        F.pray(.fajr, on: 0, in: &log)
        F.pray(.fajr, on: 1, .late, in: &log)
        try! log.setTiming(.onTime, for: .fajr, in: F.day(1), at: F.at(1, 9))

        let score = Scoring.score(log, days: F.days(2), at: F.at(1, 9))

        #expect(score.currentFajrStreak == 2)
    }

    @Test func aDateMissingFromTheDaysBreaksTheFajrStreak() {
        var log = PrayerLog()
        for index in [0, 1, 3] {
            F.pray(.fajr, on: index, in: &log)
        }

        let score = Scoring.score(log, days: [F.day(0), F.day(1), F.day(3)], at: F.at(3, 12))

        #expect(score.currentFajrStreak == 1)
        #expect(score.bestFajrStreak == 2)
    }
}
