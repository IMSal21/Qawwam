import Foundation
import Testing

@testable import QawwamCore

private let riyadh = GeoPoint(latitude: 24.7136, longitude: 46.6753)
private let riyadhTime = TimeZone(identifier: "Asia/Riyadh")!

private func riyadhInstant(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = riyadhTime
    return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

@Suite struct ScoringRiyadhTests {
    /// January 2027 in Riyadh: every prayer on time, except Isha on the 10th logged at 00:30 the next night
    /// (still on time) and Asr on the 20th never logged.
    @Test func aRealRiyadhMonth() throws {
        let calculator = PrayerTimesCalculator(settings: .ummAlQura)
        let days = try (1...31).map {
            try calculator.day(DateComponents(year: 2027, month: 1, day: $0), at: riyadh, in: riyadhTime)
        }
        var log = PrayerLog()
        for (index, day) in days.enumerated() {
            for prayer in Prayer.allCases {
                switch (index + 1, prayer) {
                case (20, .asr):
                    continue
                case (10, .isha):
                    try log.markPrayed(.isha, in: day, at: riyadhInstant(2027, 1, 11, 0, 30))
                default:
                    try log.markPrayed(prayer, in: day, at: day.time(of: prayer).addingTimeInterval(300))
                }
            }
        }

        let score = Scoring.score(log, days: days, at: riyadhInstant(2027, 2, 1, 12, 0))

        #expect(score.days.count == 31)
        #expect(score.days[9].points == 75)
        #expect(score.days[19].points == 40)
        #expect(score.currentStreak == 11)
        #expect(score.bestStreak == 19)
        #expect(score.currentFajrStreak == 31)
        #expect(score.totalPoints == 30 * 75 + 40 + 50 + 50)
        #expect(score.badges == [3, 7])
        #expect(score.level == 7)
    }

    @Test func fourHundredDaysScoreQuickly() {
        var log = PrayerLog()
        ScoringFixtures.prayAll(on: 0..<400, in: &log)
        let days = ScoringFixtures.days(400)

        let start = ContinuousClock.now
        let score = Scoring.score(log, days: days, at: ScoringFixtures.at(400, 5, 30))
        let elapsed = ContinuousClock.now - start

        #expect(score.currentStreak == 400)
        #expect(elapsed < .seconds(1))
    }
}
