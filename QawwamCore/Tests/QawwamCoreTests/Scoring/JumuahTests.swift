import Foundation
import Testing

@testable import QawwamCore

private typealias F = ScoringFixtures

/// Day 0 is Thursday 1 January 2026, so the Fridays are days 1, 8, 15, 22 and 29.
/// Dhuhr starts at 12:00 and Jumu'ah's time ends when Asr starts at 15:10.
@Suite struct JumuahTests {
    @Test func theFixtureFridaysAreFridays() {
        #expect([1, 8, 15, 22, 29].allSatisfy { DayKey(F.day($0)).weekdayIndex == 5 })
    }

    @Test func jumuahOnTimeIsFiveTimesTheOnTimePoints() {
        var log = PrayerLog()
        F.prayAll(on: [1], in: &log)

        let day = Scoring.score(log, days: [F.day(1)], at: F.at(1, 23)).days[0]

        #expect(day.points == 4 * 10 + 50 + 25)
        #expect(day.jumuahPenalty == 0)
    }

    @Test func jumuahCountsAsSoonAsItIsLogged() {
        var log = PrayerLog()
        F.pray(.dhuhr, on: 1, in: &log)

        let score = Scoring.score(log, days: [F.day(1)], at: F.at(1, 13))

        #expect(score.days[0].points == 50)
        #expect(score.totalPoints == 50)
    }

    @Test func jumuahIsMissedOnceItsTimeEnds() {
        let log = PrayerLog()

        let before = Scoring.score(log, days: [F.day(1)], at: F.at(1, 15, 9)).days[0]
        let after = Scoring.score(log, days: [F.day(1)], at: F.at(1, 15, 10)).days[0]

        #expect(before.jumuahPenalty == 0)
        #expect(after.jumuahPenalty == 50)
        #expect(Scoring.jumuahMissed(log, in: F.day(1), at: F.at(1, 15, 10)))
        #expect(!Scoring.jumuahMissed(log, in: F.day(1), at: F.at(1, 15, 9)))
    }

    @Test func missedJumuahPrayedAsDhuhrEarnsTheLatePointsAndKeepsTheStreak() {
        var log = PrayerLog()
        F.prayAll(on: [0], in: &log)
        F.prayAll(on: [1], in: &log)
        try! log.setTiming(.late, for: .dhuhr, in: F.day(1), at: F.at(1, 23))

        let score = Scoring.score(log, days: F.days(2), at: F.at(2, 5, 30))

        #expect(score.days[1].points == 4 * 10 + 5)
        #expect(score.days[1].jumuahPenalty == 50)
        #expect(score.days[1].isComplete)
        #expect(score.currentStreak == 2)
        #expect(score.totalPoints == 75 + 45 - 50)
    }

    @Test func missedJumuahWithNoDhuhrBreaksTheStreak() {
        var log = PrayerLog()
        F.prayAll(on: [0], in: &log)
        for prayer in [Prayer.fajr, .asr, .maghrib, .isha] { F.pray(prayer, on: 1, in: &log) }

        let score = Scoring.score(log, days: F.days(2), at: F.at(2, 12))

        #expect(score.days[1].points == 40)
        #expect(score.days[1].jumuahPenalty == 50)
        #expect(score.currentStreak == 0)
        #expect(score.totalPoints == 75 + 40 - 50)
    }

    @Test func thePenaltyGrowsForFridaysMissedInARowAndResetsWhenJumuahIsPrayed() {
        var log = PrayerLog()
        F.prayAll(on: 0..<36, in: &log)
        for friday in [1, 8, 15, 29] {
            try! log.setTiming(.late, for: .dhuhr, in: F.day(friday), at: F.at(friday, 23))
        }

        let score = Scoring.score(log, days: F.days(36), at: F.at(36, 5, 30))

        let fridays: [Int] = [1, 8, 15, 22, 29].map { score.days[$0].jumuahPenalty }
        #expect(fridays == [50, 60, 70, 0, 50])
        let penalties: Int = score.days.map(\.jumuahPenalty).reduce(0, +)
        #expect(penalties == 230)
    }

    @Test func switchingJumuahToOnTimeTakesThePenaltyAway() {
        var log = PrayerLog()
        F.prayAll(on: [1], in: &log)
        try! log.setTiming(.late, for: .dhuhr, in: F.day(1), at: F.at(1, 16))
        try! log.setTiming(.onTime, for: .dhuhr, in: F.day(1), at: F.at(1, 17))

        let day = Scoring.score(log, days: [F.day(1)], at: F.at(1, 23)).days[0]

        #expect(day.jumuahPenalty == 0)
        #expect(day.points == 115)
    }

    @Test func undoingJumuahAfterItsTimeBringsThePenalty() {
        var log = PrayerLog()
        F.pray(.dhuhr, on: 1, in: &log)
        try! log.unmark(.dhuhr, in: F.day(1), at: F.at(1, 16))

        let day = Scoring.score(log, days: [F.day(1)], at: F.at(1, 16)).days[0]

        #expect(day.points == 0)
        #expect(day.jumuahPenalty == 50)
    }

    @Test func otherDaysHaveNoJumuah() {
        let score = Scoring.score(PrayerLog(), days: [F.day(2)], at: F.at(3, 12))

        #expect(score.days[0].jumuahPenalty == 0)
        #expect(!Scoring.jumuahMissed(PrayerLog(), in: F.day(2), at: F.at(3, 12)))
    }

    @Test func theTotalNeverGoesBelowZero() {
        let alone = Scoring.score(PrayerLog(), days: [F.day(1)], at: F.at(2, 12))
        #expect(alone.totalPoints == 0)
        #expect(alone.level == 1)

        var log = PrayerLog()
        F.prayAll(on: [2], in: &log)
        let then = Scoring.score(log, days: [F.day(1), F.day(2)], at: F.at(2, 23))
        #expect(then.totalPoints == 75)
    }
}
