import Foundation
import Testing

@testable import QawwamCore

private typealias F = ScoringFixtures

@Suite struct DayScoreTests {
    @Test func aPerfectDayIsFiftyPlusTheTwentyFiveBonus() {
        var log = PrayerLog()
        F.prayAll(on: [0], in: &log)

        let day = Scoring.score(log, days: F.days(1), at: F.at(0, 23)).days[0]

        #expect(day.points == 75)
        #expect(day.onTimeCount == 5)
        #expect(day.prayedCount == 5)
        #expect(day.isComplete)
    }

    @Test func eachOnTimePrayerIsTenAndEachLatePrayerIsFive() {
        var log = PrayerLog()
        F.pray(.fajr, on: 0, .late, in: &log)
        F.pray(.dhuhr, on: 0, .onTime, in: &log)
        F.pray(.asr, on: 0, .late, in: &log)

        let day = Scoring.score(log, days: F.days(1), at: F.at(0, 16)).days[0]

        #expect(day.points == 20)
        #expect(day.prayedCount == 3)
        #expect(day.onTimeCount == 1)
        #expect(!day.isComplete)
    }

    @Test func allFivePrayedWithOneLateEarnsNoBonus() {
        var log = PrayerLog()
        F.prayAll(on: [0], in: &log)
        try! log.setTiming(.late, for: .asr, in: F.day(0), at: F.at(0, 23))

        let day = Scoring.score(log, days: F.days(1), at: F.at(0, 23)).days[0]

        #expect(day.points == 45)
        #expect(day.isComplete)
    }

    @Test func undoingAPrayerTakesItsPointsAndTheBonusAway() {
        var log = PrayerLog()
        F.prayAll(on: [0], in: &log)
        try! log.unmark(.isha, in: F.day(0), at: F.at(0, 23))

        let day = Scoring.score(log, days: F.days(1), at: F.at(0, 23)).days[0]

        #expect(day.points == 40)
        #expect(!day.isComplete)
    }

    @Test func pointsCountWhileTheDayIsStillOpen() {
        var log = PrayerLog()
        F.pray(.fajr, on: 0, in: &log)

        let day = Scoring.score(log, days: F.days(1), at: F.at(0, 6)).days[0]

        #expect(day.points == 10)
        #expect(!day.isClosed)
    }

    @Test func aDayClosesExactlyAtTheNextFajr() {
        let justBefore = Scoring.score(PrayerLog(), days: F.days(1), at: F.at(1, 5, 19)).days[0]
        let atFajr = Scoring.score(PrayerLog(), days: F.days(1), at: F.at(1, 5, 20)).days[0]

        #expect(!justBefore.isClosed)
        #expect(atFajr.isClosed)
        #expect(atFajr.points == 0)
    }

    @Test func daysThatHaveNotStartedAreLeftOut() {
        let score = Scoring.score(PrayerLog(), days: F.days(3), at: F.at(1, 5, 19))

        #expect(score.days.map(\.day) == [DayKey(year: 2026, month: 1, day: 1)])
    }

    @Test func daysComeBackOldestFirstWithoutDuplicates() {
        let days = [F.day(2), F.day(0), F.day(1), F.day(0)]

        let score = Scoring.score(PrayerLog(), days: days, at: F.at(3, 12))

        #expect(score.days.map(\.day.day) == [1, 2, 3])
    }
}
