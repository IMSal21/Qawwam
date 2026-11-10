import Foundation
import Testing

@testable import QawwamCore

/// A fixed prayer day so the rules are tested apart from astronomy.
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

@Suite struct MarkPrayedTests {
    @Test func loggedInsideItsWindowItIsOnTime() throws {
        var log = PrayerLog()

        try log.markPrayed(.asr, in: day, at: at(16, 0))

        #expect(log.status(of: .asr, in: day, at: at(16, 0)) == .prayed(.onTime))
    }

    @Test func loggedExactlyAtItsStartItIsOnTime() throws {
        var log = PrayerLog()

        try log.markPrayed(.dhuhr, in: day, at: at(12, 0))

        #expect(log.entry(for: .dhuhr, in: day)?.timing == .onTime)
    }

    @Test func loggedAfterItsWindowButBeforeTheNextFajrItIsLate() throws {
        var log = PrayerLog()

        try log.markPrayed(.fajr, in: day, at: at(6, 40))

        #expect(log.status(of: .fajr, in: day, at: at(6, 40)) == .prayed(.late))
    }

    @Test func theLogTimeAndCongregationFlagAreKept() throws {
        var log = PrayerLog()

        try log.markPrayed(.maghrib, in: day, at: at(17, 35), inCongregation: true)

        let expected = PrayerEntry(timing: .onTime, loggedAt: at(17, 35), inCongregation: true)
        #expect(log.entry(for: .maghrib, in: day) == expected)
    }

    @Test func congregationIsOffUnlessAsked() throws {
        var log = PrayerLog()

        try log.markPrayed(.maghrib, in: day, at: at(17, 35))

        #expect(log.entry(for: .maghrib, in: day)?.inCongregation == false)
    }

    @Test func aLoggedPrayerStaysPrayedAfterTheDayCloses() throws {
        var log = PrayerLog()

        try log.markPrayed(.isha, in: day, at: at(21, 0))

        #expect(log.status(of: .isha, in: day, at: day.nextFajr.addingTimeInterval(86_400)) == .prayed(.onTime))
    }

    @Test func otherPrayersAreUntouched() throws {
        var log = PrayerLog()

        try log.markPrayed(.asr, in: day, at: at(16, 0))

        #expect(log.status(of: .dhuhr, in: day, at: at(16, 0)) == .due)
        #expect(log.status(of: .maghrib, in: day, at: at(16, 0)) == .upcoming)
    }

    @Test func beforeItsTimeLoggingIsRefusedAndNothingIsSaved() {
        var log = PrayerLog()

        #expect(throws: PrayerLogError.notYetDue) {
            try log.markPrayed(.maghrib, in: day, at: at(17, 29))
        }
        #expect(log.isEmpty)
    }

    @Test func atTheNextFajrLoggingIsRefusedAndNothingIsSaved() {
        var log = PrayerLog()

        #expect(throws: PrayerLogError.dayClosed) {
            try log.markPrayed(.isha, in: day, at: day.nextFajr)
        }
        #expect(log.isEmpty)
    }

    @Test func markingTwiceKeepsTheFirstEntry() throws {
        var log = PrayerLog()
        try log.markPrayed(.asr, in: day, at: at(16, 0), inCongregation: true)

        try log.markPrayed(.asr, in: day, at: at(18, 0))

        let first = PrayerEntry(timing: .onTime, loggedAt: at(16, 0), inCongregation: true)
        #expect(log.entry(for: .asr, in: day) == first)
    }

    @Test func eachDayKeepsItsOwnEntries() throws {
        let nextDay = PrayerDay(
            date: DateComponents(year: 2026, month: 1, day: 2),
            times: [
                .fajr: at(29, 20), .dhuhr: at(36, 0), .asr: at(39, 10),
                .maghrib: at(41, 30), .isha: at(43, 0),
            ],
            sunrise: at(30, 40),
            nextFajr: at(53, 20)
        )
        var log = PrayerLog()

        try log.markPrayed(.fajr, in: nextDay, at: at(29, 30))

        #expect(log.status(of: .fajr, in: nextDay, at: at(29, 30)) == .prayed(.onTime))
        #expect(log.status(of: .fajr, in: day, at: at(29, 30)) == .missed)
    }
}
