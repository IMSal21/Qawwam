import Foundation
import Testing

@testable import QawwamCore

private typealias F = ScoringFixtures

/// A score after `count` perfect days in a row, read just after the last day closes.
private func scoreAfterPerfectDays(_ count: Int) -> Score {
    var log = PrayerLog()
    F.prayAll(on: 0..<count, in: &log)
    return Scoring.score(log, days: F.days(count), at: F.at(count, 5, 30))
}

@Suite struct MilestoneTests {
    @Test(arguments: [
        (6, 0), (7, 50), (29, 50), (30, 150), (39, 150), (40, 300), (99, 300), (100, 600),
    ])
    func streakBonusesArriveExactlyAtTheirDay(days: Int, bonusSoFar: Int) {
        let score = scoreAfterPerfectDays(days)

        #expect(score.totalPoints == days * 75 + bonusSoFar)
    }

    @Test(arguments: [
        (2, [Int]()), (3, [3]), (6, [3]), (7, [3, 7]), (29, [3, 7]), (30, [3, 7, 30]),
        (40, [3, 7, 30, 40]), (99, [3, 7, 30, 40]), (100, [3, 7, 30, 40, 100]),
    ])
    func badgesArriveExactlyAtTheirDay(days: Int, badges: [Int]) {
        #expect(scoreAfterPerfectDays(days).badges == badges)
    }

    @Test func theSevenDayBonusIsEarnedAgainAfterAReset() {
        var log = PrayerLog()
        F.prayAll(on: 0..<7, in: &log)
        F.prayAll(on: 8..<15, in: &log)

        let score = Scoring.score(log, days: F.days(15), at: F.at(15, 5, 30))

        #expect(score.totalPoints == 14 * 75 + 2 * 50)
    }

    @Test func badgesStayAfterAReset() {
        var log = PrayerLog()
        F.prayAll(on: 0..<7, in: &log)

        let score = Scoring.score(log, days: F.days(9), at: F.at(9, 5, 30))

        #expect(score.currentStreak == 0)
        #expect(score.badges == [3, 7])
    }

    @Test func theBonusCountsAsSoonAsTodayCompletesTheSeventhDay() {
        var log = PrayerLog()
        F.prayAll(on: 0..<7, in: &log)

        let score = Scoring.score(log, days: F.days(7), at: F.at(6, 19, 10))

        #expect(score.currentStreak == 7)
        #expect(score.totalPoints == 7 * 75 + 50)
    }

    @Test func lateDaysCountTowardsMilestonesToo() {
        var log = PrayerLog()
        F.prayAll(on: 0..<7, .late, in: &log)

        let score = Scoring.score(log, days: F.days(7), at: F.at(7, 5, 30))

        #expect(score.totalPoints == 7 * 25 + 50)
        #expect(score.badges == [3, 7])
    }

    @Test func totalPointsAddPartialDaysToo() {
        var log = PrayerLog()
        F.prayAll(on: [0], in: &log)
        F.pray(.fajr, on: 1, .late, in: &log)
        F.pray(.dhuhr, on: 1, in: &log)

        let score = Scoring.score(log, days: F.days(2), at: F.at(1, 13))

        #expect(score.totalPoints == 75 + 5 + 10)
    }
}
