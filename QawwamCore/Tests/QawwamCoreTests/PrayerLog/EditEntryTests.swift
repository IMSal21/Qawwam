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

@Suite struct SetTimingTests {
    @Test func aLateEntryCanBeChangedToOnTime() throws {
        var log = PrayerLog()
        try log.markPrayed(.fajr, in: day, at: at(8, 0))

        try log.setTiming(.onTime, for: .fajr, in: day, at: at(8, 1))

        #expect(log.status(of: .fajr, in: day, at: at(8, 1)) == .prayed(.onTime))
    }

    @Test func anOnTimeEntryCanBeChangedBackToLate() throws {
        var log = PrayerLog()
        try log.markPrayed(.asr, in: day, at: at(16, 0))

        try log.setTiming(.late, for: .asr, in: day, at: at(16, 1))

        #expect(log.status(of: .asr, in: day, at: at(16, 1)) == .prayed(.late))
    }

    @Test func changingTheTimingKeepsTheLogTimeAndCongregation() throws {
        var log = PrayerLog()
        try log.markPrayed(.fajr, in: day, at: at(8, 0), inCongregation: true)

        try log.setTiming(.onTime, for: .fajr, in: day, at: at(8, 1))

        let expected = PrayerEntry(timing: .onTime, loggedAt: at(8, 0), inCongregation: true)
        #expect(log.entry(for: .fajr, in: day) == expected)
    }

    @Test func anUnloggedPrayerCantChangeTiming() {
        var log = PrayerLog()

        #expect(throws: PrayerLogError.notLogged) {
            try log.setTiming(.onTime, for: .dhuhr, in: day, at: at(13, 0))
        }
        #expect(log.isEmpty)
    }

    @Test func afterTheDayClosesTheTimingCantChange() throws {
        var log = PrayerLog()
        try log.markPrayed(.fajr, in: day, at: at(8, 0))

        #expect(throws: PrayerLogError.dayClosed) {
            try log.setTiming(.onTime, for: .fajr, in: day, at: day.nextFajr)
        }
        #expect(log.entry(for: .fajr, in: day)?.timing == .late)
    }
}

@Suite struct UnmarkTests {
    @Test func undoingALogMakesThePrayerDueAgain() throws {
        var log = PrayerLog()
        try log.markPrayed(.asr, in: day, at: at(16, 0))

        try log.unmark(.asr, in: day, at: at(16, 5))

        #expect(log.entry(for: .asr, in: day) == nil)
        #expect(log.status(of: .asr, in: day, at: at(16, 5)) == .due)
    }

    @Test func undoingTheOnlyLogLeavesAnEmptyLog() throws {
        var log = PrayerLog()
        try log.markPrayed(.asr, in: day, at: at(16, 0))

        try log.unmark(.asr, in: day, at: at(16, 5))

        #expect(log == PrayerLog())
    }

    @Test func undoingOnePrayerKeepsTheOthers() throws {
        var log = PrayerLog()
        try log.markPrayed(.dhuhr, in: day, at: at(12, 30))
        try log.markPrayed(.asr, in: day, at: at(16, 0))

        try log.unmark(.asr, in: day, at: at(16, 5))

        #expect(log.status(of: .dhuhr, in: day, at: at(16, 5)) == .prayed(.onTime))
    }

    @Test func anUnloggedPrayerCantBeUndone() {
        var log = PrayerLog()

        #expect(throws: PrayerLogError.notLogged) {
            try log.unmark(.dhuhr, in: day, at: at(13, 0))
        }
    }

    @Test func afterTheDayClosesALogCantBeUndone() throws {
        var log = PrayerLog()
        try log.markPrayed(.isha, in: day, at: at(21, 0))

        #expect(throws: PrayerLogError.dayClosed) {
            try log.unmark(.isha, in: day, at: day.nextFajr)
        }
        #expect(log.status(of: .isha, in: day, at: day.nextFajr) == .prayed(.onTime))
    }
}
