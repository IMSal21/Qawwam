import Foundation
import Testing

@testable import QawwamCore

private let riyadh = GeoPoint(latitude: 24.7136, longitude: 46.6753)
private let saudi = TimeZone(identifier: "Asia/Riyadh")!

@Suite struct PrayerDayLookupTests {
    let calculator = PrayerTimesCalculator(settings: .ummAlQura)

    @Test func middayBelongsToThatDay() throws {
        let jan1 = try calculator.day(DateComponents(year: 2026, month: 1, day: 1), at: riyadh, in: saudi)
        let noon = jan1.time(of: .dhuhr).addingTimeInterval(30 * 60)

        let found = try calculator.prayerDay(containing: noon, at: riyadh, in: saudi)

        #expect(found == jan1)
    }

    @Test func oneInTheMorningBelongsToThePreviousDay() throws {
        let jan1 = try calculator.day(DateComponents(year: 2026, month: 1, day: 1), at: riyadh, in: saudi)
        let jan2OneAM = Date(timeIntervalSince1970: 1_767_304_800)  // 2026-01-02 01:00 Asia/Riyadh

        let found = try calculator.prayerDay(containing: jan2OneAM, at: riyadh, in: saudi)

        #expect(found == jan1)
    }

    @Test func exactlyAtFajrStartsTheNewDay() throws {
        let jan2 = try calculator.day(DateComponents(year: 2026, month: 1, day: 2), at: riyadh, in: saudi)

        let found = try calculator.prayerDay(containing: jan2.time(of: .fajr), at: riyadh, in: saudi)

        #expect(found == jan2)
    }

    @Test func justBeforeFajrBelongsToThePreviousDay() throws {
        let jan2 = try calculator.day(DateComponents(year: 2026, month: 1, day: 2), at: riyadh, in: saudi)

        let found = try calculator.prayerDay(
            containing: jan2.time(of: .fajr).addingTimeInterval(-1), at: riyadh, in: saudi)

        #expect(found.date == DateComponents(year: 2026, month: 1, day: 1))
    }
}
