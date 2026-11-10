import Foundation
import Testing

@testable import QawwamCore

private typealias F = ScoringFixtures

@Suite struct StreakTests {
    @Test func completeDaysInARowMakeTheStreak() {
        var log = PrayerLog()
        F.prayAll(on: 0..<3, in: &log)

        let score = Scoring.score(log, days: F.days(4), at: F.at(3, 5, 30))

        #expect(score.currentStreak == 3)
        #expect(score.bestStreak == 3)
    }

    @Test func latePrayersStillCountForTheStreak() {
        var log = PrayerLog()
        F.prayAll(on: 0..<2, .late, in: &log)

        let score = Scoring.score(log, days: F.days(3), at: F.at(2, 5, 30))

        #expect(score.currentStreak == 2)
    }

    @Test func aClosedDayWithAMissedPrayerResetsTheStreakToZero() {
        var log = PrayerLog()
        F.prayAll(on: 0..<3, in: &log)
        F.prayAll(on: [3], in: &log)
        try! log.unmark(.asr, in: F.day(3), at: F.at(3, 23))

        let score = Scoring.score(log, days: F.days(5), at: F.at(4, 5, 30))

        #expect(score.currentStreak == 0)
        #expect(score.bestStreak == 3)
    }

    @Test func theStreakStartsAgainAfterAReset() {
        var log = PrayerLog()
        F.prayAll(on: 0..<3, in: &log)
        F.prayAll(on: 4..<6, in: &log)

        let score = Scoring.score(log, days: F.days(7), at: F.at(6, 5, 30))

        #expect(score.currentStreak == 2)
        #expect(score.bestStreak == 3)
    }

    @Test(arguments: [0, 3])
    func todayOpenAndUnfinishedDoesNotBreakTheStreak(prayedToday: Int) {
        var log = PrayerLog()
        F.prayAll(on: 0..<2, in: &log)
        for prayer in Prayer.allCases.prefix(prayedToday) {
            F.pray(prayer, on: 2, in: &log)
        }

        let score = Scoring.score(log, days: F.days(3), at: F.at(2, 18))

        #expect(score.currentStreak == 2)
    }

    @Test func todayAddsToTheStreakAsSoonAsAllFiveArePrayed() {
        var log = PrayerLog()
        F.prayAll(on: 0..<3, in: &log)

        let score = Scoring.score(log, days: F.days(3), at: F.at(2, 19, 10))

        #expect(score.currentStreak == 3)
    }

    @Test func aDayWithNoLogsAtAllBreaksTheStreak() {
        var log = PrayerLog()
        F.prayAll(on: [0, 1, 3], in: &log)

        let score = Scoring.score(log, days: F.days(4), at: F.at(4, 5, 30))

        #expect(score.currentStreak == 1)
        #expect(score.bestStreak == 2)
    }

    @Test func aDateMissingFromTheDaysBreaksTheStreak() {
        var log = PrayerLog()
        F.prayAll(on: [0, 1, 3], in: &log)
        let daysWithAGap = [F.day(0), F.day(1), F.day(3)]

        let score = Scoring.score(log, days: daysWithAGap, at: F.at(4, 5, 30))

        #expect(score.currentStreak == 1)
        #expect(score.bestStreak == 2)
    }

    @Test func theStreakCountsAcrossAMonthEnd() {
        var log = PrayerLog()
        F.prayAll(on: 29..<33, in: &log)  // 30 January to 2 February

        let score = Scoring.score(log, days: Array(F.days(33)[29...]), at: F.at(33, 5, 30))

        #expect(score.currentStreak == 4)
    }

    @Test func noDaysMeansNoStreak() {
        let score = Scoring.score(PrayerLog(), days: [], at: F.at(0, 12))

        #expect(score.currentStreak == 0)
        #expect(score.bestStreak == 0)
        #expect(score.days.isEmpty)
    }
}
