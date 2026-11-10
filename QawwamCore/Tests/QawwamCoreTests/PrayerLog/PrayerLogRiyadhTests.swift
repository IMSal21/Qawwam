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

@Suite struct PrayerLogRiyadhTests {
    @Test func ishaLoggedAfterMidnightBelongsToThePreviousPrayerDayAndIsOnTime() throws {
        let calculator = PrayerTimesCalculator(settings: .ummAlQura)
        let halfPastMidnight = riyadhInstant(2027, 1, 16, 0, 30)
        let day = try calculator.prayerDay(containing: halfPastMidnight, at: riyadh, in: riyadhTime)
        var log = PrayerLog()

        try log.markPrayed(.isha, in: day, at: halfPastMidnight)

        #expect(DayKey(day) == DayKey(year: 2027, month: 1, day: 15))
        #expect(log.status(of: .isha, in: day, at: halfPastMidnight) == .prayed(.onTime))
    }

    @Test func afterMidnightTheDayIsStillOpenUntilFajr() throws {
        let calculator = PrayerTimesCalculator(settings: .ummAlQura)
        let halfPastMidnight = riyadhInstant(2027, 1, 16, 0, 30)
        let day = try calculator.prayerDay(containing: halfPastMidnight, at: riyadh, in: riyadhTime)
        var log = PrayerLog()

        try log.markPrayed(.maghrib, in: day, at: halfPastMidnight)

        #expect(log.status(of: .maghrib, in: day, at: halfPastMidnight) == .prayed(.late))
        #expect(log.status(of: .asr, in: day, at: day.nextFajr) == .missed)
        #expect(throws: PrayerLogError.dayClosed) {
            try log.markPrayed(.asr, in: day, at: day.nextFajr)
        }
    }
}
