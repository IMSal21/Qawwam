import Foundation
import Testing

@testable import QawwamCore

private let saudi = TimeZone(identifier: "Asia/Riyadh")!

/// The far north (near Turaif) and far south (near Al-Tuwal) of the Kingdom,
/// on both solstices, where days are longest and shortest.
private let extremes: [(String, GeoPoint)] = [
    ("north", GeoPoint(latitude: 31.67, longitude: 38.66)),
    ("south", GeoPoint(latitude: 16.40, longitude: 42.80)),
]
private let solstices = [
    DateComponents(year: 2026, month: 6, day: 21),
    DateComponents(year: 2026, month: 12, day: 21),
]

@Suite struct EdgeCaseTests {
    let calculator = PrayerTimesCalculator(settings: .ummAlQura)

    @Test(arguments: extremes, solstices)
    func timesFallInOrderAtTheKingdomsExtremes(place: (String, GeoPoint), date: DateComponents) throws {
        let day = try calculator.day(date, at: place.1, in: saudi)

        let ordered = [
            day.time(of: .fajr), day.sunrise, day.time(of: .dhuhr), day.time(of: .asr),
            day.time(of: .maghrib), day.time(of: .isha), day.nextFajr,
        ]
        #expect(ordered == ordered.sorted())
    }

    @Test(arguments: extremes, solstices)
    func everyPrayerWindowIsAtLeastAnHour(place: (String, GeoPoint), date: DateComponents) throws {
        let day = try calculator.day(date, at: place.1, in: saudi)

        for prayer in Prayer.allCases {
            #expect(day.window(for: prayer).duration >= 3600)
        }
    }

    @Test func largestAdjustmentsStillGiveOrderedTimes() throws {
        var settings = PrayerSettings.ummAlQura
        settings.setAdjustment(30, for: .maghrib)
        settings.setAdjustment(-30, for: .isha)
        let riyadh = GeoPoint(latitude: 24.7136, longitude: 46.6753)

        let day = try PrayerTimesCalculator(settings: settings)
            .day(DateComponents(year: 2026, month: 1, day: 1), at: riyadh, in: saudi)

        #expect(day.time(of: .maghrib) < day.time(of: .isha))
    }
}
