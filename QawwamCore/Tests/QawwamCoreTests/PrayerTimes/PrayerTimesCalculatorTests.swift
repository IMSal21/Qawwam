import Foundation
import Testing

@testable import QawwamCore

private let riyadh = GeoPoint(latitude: 24.7136, longitude: 46.6753)
private let saudi = TimeZone(identifier: "Asia/Riyadh")!
private let outsideRamadan = DateComponents(year: 2026, month: 1, day: 1)  // Rajab 1447
private let inRamadan = DateComponents(year: 2026, month: 3, day: 1)  // Ramadan 1447

private func minutes(_ from: Date, _ to: Date) -> Double {
    to.timeIntervalSince(from) / 60
}

@Suite struct PrayerTimesCalculatorTests {
    let calculator = PrayerTimesCalculator(settings: .ummAlQura)

    @Test func timesFallInDailyOrder() throws {
        let day = try calculator.day(outsideRamadan, at: riyadh, in: saudi)

        let ordered = [
            day.time(of: .fajr), day.sunrise, day.time(of: .dhuhr), day.time(of: .asr),
            day.time(of: .maghrib), day.time(of: .isha), day.nextFajr,
        ]
        #expect(ordered == ordered.sorted())
    }

    @Test func dhuhrInRiyadhIsAroundMidday() throws {
        let day = try calculator.day(outsideRamadan, at: riyadh, in: saudi)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = saudi
        let dhuhr = calendar.dateComponents([.hour, .minute], from: day.time(of: .dhuhr))
        let minutesAfterMidnight = dhuhr.hour! * 60 + dhuhr.minute!
        #expect((11 * 60 + 50)...(12 * 60 + 10) ~= minutesAfterMidnight)
    }

    @Test func ishaIsNinetyMinutesAfterMaghribOutsideRamadan() throws {
        let day = try calculator.day(outsideRamadan, at: riyadh, in: saudi)

        #expect(minutes(day.time(of: .maghrib), day.time(of: .isha)) == 90)
    }

    @Test func ishaIsTwoHoursAfterMaghribInRamadan() throws {
        let day = try calculator.day(inRamadan, at: riyadh, in: saudi)

        #expect(minutes(day.time(of: .maghrib), day.time(of: .isha)) == 120)
    }

    @Test func nextFajrIsTheFollowingDaysFajr() throws {
        let today = try calculator.day(outsideRamadan, at: riyadh, in: saudi)
        let tomorrow = try calculator.day(DateComponents(year: 2026, month: 1, day: 2), at: riyadh, in: saudi)

        #expect(today.nextFajr == tomorrow.time(of: .fajr))
    }

    @Test(arguments: Prayer.allCases)
    func adjustmentShiftsOnlyThatPrayer(prayer: Prayer) throws {
        var adjusted = PrayerSettings.ummAlQura
        adjusted.setAdjustment(5, for: prayer)

        let base = try calculator.day(outsideRamadan, at: riyadh, in: saudi)
        let shifted = try PrayerTimesCalculator(settings: adjusted).day(outsideRamadan, at: riyadh, in: saudi)

        for other in Prayer.allCases {
            let expected: Double = other == prayer ? 5 : 0
            #expect(minutes(base.time(of: other), shifted.time(of: other)) == expected)
        }
    }

    @Test func hanafiAsrIsLaterThanStandardAsr() throws {
        var hanafi = PrayerSettings.ummAlQura
        hanafi.madhab = .hanafi

        let standardDay = try calculator.day(outsideRamadan, at: riyadh, in: saudi)
        let hanafiDay = try PrayerTimesCalculator(settings: hanafi).day(outsideRamadan, at: riyadh, in: saudi)

        #expect(minutes(standardDay.time(of: .asr), hanafiDay.time(of: .asr)) > 30)
    }

    @Test func dayRemembersItsDate() throws {
        let day = try calculator.day(outsideRamadan, at: riyadh, in: saudi)

        #expect(day.date == outsideRamadan)
    }
}

@Suite struct RoundingTests {
    @Test func prayerStartsRoundUpToTheNextMinute() {
        let raw = Date(timeIntervalSince1970: 60 * 1000 + 1)

        #expect(PrayerTimesCalculator.roundedUp(raw) == Date(timeIntervalSince1970: 60 * 1001))
    }

    @Test func sunriseRoundsDownToTheMinute() {
        let raw = Date(timeIntervalSince1970: 60 * 1000 + 59)

        #expect(PrayerTimesCalculator.roundedDown(raw) == Date(timeIntervalSince1970: 60 * 1000))
    }

    @Test func wholeMinutesAreLeftAlone() {
        let exact = Date(timeIntervalSince1970: 60 * 1000)

        #expect(PrayerTimesCalculator.roundedUp(exact) == exact)
        #expect(PrayerTimesCalculator.roundedDown(exact) == exact)
    }
}
