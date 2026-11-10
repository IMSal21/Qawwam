import Foundation

@testable import QawwamCore

/// Hand-built prayer days with round times, so scoring is tested apart from astronomy.
/// Day 0 is 2026-01-01 in Riyadh. Every day has the same times:
/// Fajr 05:20, sunrise 06:40, Dhuhr 12:00, Asr 15:10, Maghrib 17:30, Isha 19:00, next Fajr 05:20.
enum ScoringFixtures {
    static let riyadh = TimeZone(identifier: "Asia/Riyadh")!
    static let firstMidnight = Date(timeIntervalSince1970: 1_767_214_800)  // 2026-01-01 00:00 Asia/Riyadh

    /// An instant on day `index` (0 = 2026-01-01). Hours past 24 run into the next day.
    static func at(_ index: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        firstMidnight.addingTimeInterval(TimeInterval(index * 86_400 + hour * 3600 + minute * 60))
    }

    static func day(_ index: Int) -> PrayerDay {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = riyadh
        let date = calendar.dateComponents([.year, .month, .day], from: at(index, 12))
        return PrayerDay(
            date: DateComponents(year: date.year, month: date.month, day: date.day),
            times: [
                .fajr: at(index, 5, 20), .dhuhr: at(index, 12), .asr: at(index, 15, 10),
                .maghrib: at(index, 17, 30), .isha: at(index, 19),
            ],
            sunrise: at(index, 6, 40),
            nextFajr: at(index + 1, 5, 20)
        )
    }

    /// Days 0 up to `count - 1`.
    static func days(_ count: Int) -> [PrayerDay] {
        (0..<count).map(day)
    }

    /// Logs `prayer` on day `index` five minutes after it starts, then sets the timing asked for.
    static func pray(_ prayer: Prayer, on index: Int, _ timing: PrayerTiming = .onTime, in log: inout PrayerLog) {
        let day = day(index)
        let loggedAt = day.time(of: prayer).addingTimeInterval(300)
        try! log.markPrayed(prayer, in: day, at: loggedAt)
        try! log.setTiming(timing, for: prayer, in: day, at: loggedAt)
    }

    /// Logs all five prayers on each of `indices`, all with the same timing.
    static func prayAll(on indices: some Sequence<Int>, _ timing: PrayerTiming = .onTime, in log: inout PrayerLog) {
        for index in indices {
            for prayer in Prayer.allCases {
                pray(prayer, on: index, timing, in: &log)
            }
        }
    }
}
