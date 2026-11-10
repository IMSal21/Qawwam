import Foundation
import Testing

@testable import QawwamCore

@Suite struct TimeWordsTests {
    static let arabic = Words(.arabic)
    static let english = Words(.english)

    /// A Riyadh wall-clock time on 2026-11-10.
    static func riyadh(_ hour: Int, _ minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Riyadh")!
        return calendar.date(from: DateComponents(year: 2026, month: 11, day: 10, hour: hour, minute: minute))!
    }

    @Test(arguments: [
        (5, 20, "5:20 ص", "5:20 AM"), (19, 45, "7:45 م", "7:45 PM"), (0, 0, "12:00 ص", "12:00 AM"),
        (12, 0, "12:00 م", "12:00 PM"), (11, 59, "11:59 ص", "11:59 AM"), (23, 5, "11:05 م", "11:05 PM"),
    ])
    func twelveHourClock(hour: Int, minute: Int, arabic: String, english: String) {
        #expect(Self.arabic.time(Self.riyadh(hour, minute)) == arabic)
        #expect(Self.english.time(Self.riyadh(hour, minute)) == english)
    }

    @Test func alwaysRiyadhTimeWhateverTheInstant() {
        // 02:20 UTC is 5:20 in Riyadh (UTC+3, no daylight saving).
        let utc = Date(timeIntervalSince1970: 1_793_499_600)  // 2026-11-01T02:20:00Z
        #expect(Self.arabic.time(utc) == "5:20 ص")
    }
}
