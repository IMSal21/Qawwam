import Foundation
import Testing

@testable import QawwamCore

/// A fixed prayer day so window rules are tested apart from astronomy.
/// Times are minutes after an arbitrary midnight.
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

@Suite struct PrayerWindowTests {
    @Test(arguments: [
        (Prayer.fajr, at(5, 20), at(6, 40)),
        (.dhuhr, at(12, 0), at(15, 10)),
        (.asr, at(15, 10), at(17, 30)),
        (.maghrib, at(17, 30), at(19, 0)),
        (.isha, at(19, 0), at(29, 20)),
    ])
    func windowRunsFromThePrayerToTheNextBoundary(prayer: Prayer, opens: Date, closes: Date) {
        let window = day.window(for: prayer)

        #expect(window.start == opens)
        #expect(window.end == closes)
    }

    @Test func loggedInsideTheWindowIsOnTime() {
        #expect(day.timing(of: .asr, loggedAt: at(16, 10)) == .onTime)
    }

    @Test func loggedAfterTheWindowIsLate() {
        #expect(day.timing(of: .asr, loggedAt: at(18, 0)) == .late)
    }

    @Test func loggedExactlyAtTheStartIsOnTime() {
        #expect(day.timing(of: .dhuhr, loggedAt: at(12, 0)) == .onTime)
    }

    @Test func loggedExactlyAtTheEndIsLate() {
        #expect(day.timing(of: .fajr, loggedAt: at(6, 40)) == .late)
    }

    @Test func ishaAfterMidnightIsStillOnTime() {
        #expect(day.timing(of: .isha, loggedAt: at(25, 30)) == .onTime)
    }

    @Test func fajrAfterSunriseIsLate() {
        #expect(day.timing(of: .fajr, loggedAt: at(7, 0)) == .late)
    }
}
