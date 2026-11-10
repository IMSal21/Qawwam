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

@Suite struct PrayerStatusTests {
    @Test(arguments: Prayer.allCases)
    func beforeItsTimeAPrayerIsUpcoming(prayer: Prayer) {
        let oneMinuteBefore = day.time(of: prayer).addingTimeInterval(-60)

        #expect(PrayerLog().status(of: prayer, in: day, at: oneMinuteBefore) == .upcoming)
    }

    @Test(arguments: Prayer.allCases)
    func exactlyAtItsTimeAPrayerIsDue(prayer: Prayer) {
        #expect(PrayerLog().status(of: prayer, in: day, at: day.time(of: prayer)) == .due)
    }

    @Test func anUnloggedPrayerStaysDueAfterItsWindowCloses() {
        #expect(PrayerLog().status(of: .dhuhr, in: day, at: at(20, 0)) == .due)
    }

    @Test func anUnloggedPrayerStaysDueOneSecondBeforeTheNextFajr() {
        let justBefore = day.nextFajr.addingTimeInterval(-1)

        #expect(PrayerLog().status(of: .isha, in: day, at: justBefore) == .due)
    }

    @Test(arguments: Prayer.allCases)
    func exactlyAtTheNextFajrAnUnloggedPrayerIsMissed(prayer: Prayer) {
        #expect(PrayerLog().status(of: prayer, in: day, at: day.nextFajr) == .missed)
    }

    @Test func daysLaterAnUnloggedPrayerIsStillMissed() {
        let threeDaysLater = day.nextFajr.addingTimeInterval(3 * 86_400)

        #expect(PrayerLog().status(of: .asr, in: day, at: threeDaysLater) == .missed)
    }

    @Test func anUnloggedPrayerHasNoEntry() {
        #expect(PrayerLog().entry(for: .fajr, in: day) == nil)
    }
}
