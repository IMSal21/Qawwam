import Foundation
import Testing

@testable import QawwamCore

private let midnight = Date(timeIntervalSince1970: 1_767_214_800)  // 2026-01-01 00:00 Asia/Riyadh
private func at(_ hour: Int, _ minute: Int) -> Date {
    midnight.addingTimeInterval(TimeInterval(hour * 3600 + minute * 60))
}

private let day = PrayerDay(
    date: DateComponents(year: 2026, month: 1, day: 1),
    times: [
        .fajr: at(5, 20), .dhuhr: at(12, 0), .asr: at(15, 10),
        .maghrib: at(17, 30), .isha: at(19, 0),
    ],
    sunrise: at(6, 40),
    nextFajr: at(29, 20)
)

@Suite struct CongregationTests {
    @Test func congregationCanBeTurnedOnAndOffAfterLogging() throws {
        var log = PrayerLog()
        try log.markPrayed(.dhuhr, in: day, at: at(12, 10))

        try log.setCongregation(true, for: .dhuhr, in: day, at: at(12, 20))
        #expect(log.entry(for: .dhuhr, in: day)?.inCongregation == true)

        try log.setCongregation(false, for: .dhuhr, in: day, at: at(12, 30))
        #expect(log.entry(for: .dhuhr, in: day)?.inCongregation == false)
    }

    @Test func changingCongregationKeepsTimingAndLogTime() throws {
        var log = PrayerLog()
        try log.markPrayed(.fajr, in: day, at: at(8, 0))
        let before = try #require(log.entry(for: .fajr, in: day))

        try log.setCongregation(true, for: .fajr, in: day, at: at(8, 1))

        let after = try #require(log.entry(for: .fajr, in: day))
        #expect(after.timing == before.timing)
        #expect(after.loggedAt == before.loggedAt)
    }

    @Test func anUnloggedPrayerCannotChange() {
        var log = PrayerLog()
        #expect(throws: PrayerLogError.notLogged) {
            try log.setCongregation(true, for: .asr, in: day, at: at(16, 0))
        }
    }

    @Test func aClosedDayCannotChange() throws {
        var log = PrayerLog()
        try log.markPrayed(.isha, in: day, at: at(19, 5))
        #expect(throws: PrayerLogError.dayClosed) {
            try log.setCongregation(true, for: .isha, in: day, at: at(29, 30))
        }
    }

    @Test func congregationSurvivesSaving() throws {
        var log = PrayerLog()
        try log.markPrayed(.maghrib, in: day, at: at(17, 35))
        try log.setCongregation(true, for: .maghrib, in: day, at: at(17, 40))

        let decoded = try JSONDecoder().decode(PrayerLog.self, from: JSONEncoder().encode(log))

        #expect(decoded == log)
        #expect(decoded.entry(for: .maghrib, in: day)?.inCongregation == true)
    }
}
