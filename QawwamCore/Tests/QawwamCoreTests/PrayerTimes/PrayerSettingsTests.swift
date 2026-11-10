import Foundation
import Testing

@testable import QawwamCore

@Suite struct PrayerSettingsTests {
    @Test func prayersAreInDailyOrder() {
        #expect(Prayer.allCases == [.fajr, .dhuhr, .asr, .maghrib, .isha])
    }

    @Test func defaultIsUmmAlQuraWithStandardAsrAndNoAdjustments() {
        let settings = PrayerSettings.ummAlQura

        #expect(settings.method == .ummAlQura)
        #expect(settings.madhab == .standard)
        for prayer in Prayer.allCases {
            #expect(settings.adjustment(for: prayer) == 0)
        }
    }

    @Test func hanafiAsrCanBeChosen() {
        var settings = PrayerSettings.ummAlQura
        settings.madhab = .hanafi

        #expect(settings.madhab == .hanafi)
    }

    @Test func adjustmentIsStoredPerPrayer() {
        var settings = PrayerSettings.ummAlQura
        settings.setAdjustment(5, for: .maghrib)

        #expect(settings.adjustment(for: .maghrib) == 5)
        #expect(settings.adjustment(for: .isha) == 0)
    }

    @Test(arguments: [(45, 30), (-45, -30), (30, 30), (-30, -30), (12, 12)])
    func adjustmentIsClampedToThirtyMinutes(requested: Int, stored: Int) {
        var settings = PrayerSettings.ummAlQura
        settings.setAdjustment(requested, for: .fajr)

        #expect(settings.adjustment(for: .fajr) == stored)
    }

    @Test func initializerClampsAdjustments() {
        let settings = PrayerSettings(method: .ummAlQura, madhab: .standard, adjustments: [.asr: 90])

        #expect(settings.adjustment(for: .asr) == 30)
    }

    @Test func settingsSurviveAnEncodeDecodeRoundTrip() throws {
        var settings = PrayerSettings.ummAlQura
        settings.madhab = .hanafi
        settings.setAdjustment(-3, for: .dhuhr)

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(PrayerSettings.self, from: data)

        #expect(decoded == settings)
    }
}
