import Foundation
import QawwamCore
import Testing

@testable import Qawwam

@Suite struct TodayModelTests {
    static let saudi = TimeZone(identifier: "Asia/Riyadh")!

    static func riyadh(_ year: Int, _ month: Int, _ day: Int, _ hour: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = saudi
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test func fiveRowsInArabicWithJumuahOnFriday() throws {
        // 2026-11-13 is a Friday.
        let model = try TodayModel(words: Words(.arabic), now: Self.riyadh(2026, 11, 13, 10))

        #expect(model.rows.map(\.name) == ["الفجر", "الجمعة", "العصر", "المغرب", "العشاء"])
        #expect(model.weekday == "الجمعة")
        #expect(model.gregorian == "13 نوفمبر 2026م")
        #expect(model.hijri.hasSuffix("1448 هـ"))
    }

    @Test func timesAreTodaysRiyadhTimes() throws {
        let now = Self.riyadh(2026, 11, 10, 9)
        let words = Words(.english)
        let day = try PrayerTimesCalculator(settings: .ummAlQura)
            .prayerDay(containing: now, at: TodayModel.riyadh, in: Self.saudi)

        let model = try TodayModel(words: words, now: now)

        #expect(model.rows.map(\.name) == ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"])
        #expect(model.rows.map(\.time) == Prayer.allCases.map { words.time(day.time(of: $0)) })
        #expect(model.rows.first?.time.hasSuffix("AM") == true)
    }

    @Test func justAfterMidnightIsStillThePreviousPrayerDay() throws {
        // 01:00 on Saturday the 14th is before Fajr, so it belongs to Friday's prayer day.
        let model = try TodayModel(words: Words(.english), now: Self.riyadh(2026, 11, 14, 1))
        #expect(model.weekday == "Friday")
    }
}
