import Foundation
import QawwamCore
import Testing

@testable import Qawwam

@MainActor
@Suite struct TodayStoreCityTests {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let defaults = UserDefaults(suiteName: UUID().uuidString)!
    let jeddah = SaudiCities.city(id: "jeddah")!
    let now: Date = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Riyadh")!
        return calendar.date(from: DateComponents(year: 2026, month: 11, day: 10, hour: 15, minute: 20))!
    }()

    private func makeStore() throws -> TodayStore {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = FilePrayerLogStore(fileURL: folder.appendingPathComponent("prayer-log.json"))
        let now = now
        return TodayStore(store: file, defaults: defaults, words: Words(.arabic), clock: { now })
    }

    @Test func withNoSavedCityItIsRiyadhAndOnboardingIsDue() throws {
        let store = try makeStore()
        #expect(store.city == SaudiCities.riyadh)
        #expect(!store.isOnboarded)
        #expect(store.state.gregorianLine.hasSuffix("الرياض"))
    }

    @Test func theChosenCityGivesItsTimesAndName() throws {
        OnboardingSettings(isDone: true, city: jeddah).save(to: defaults)
        let store = try makeStore()
        let expected = try PrayerTimesCalculator(settings: .ummAlQura)
            .prayerDay(containing: now, at: jeddah.location, in: TodayStore.saudi)

        #expect(store.city == jeddah)
        #expect(store.isOnboarded)
        #expect(store.days.last == expected)
        #expect(store.state.gregorianLine.hasSuffix("جدة"))
    }

    @Test func finishingOnboardingIsSavedAndSurvivesARestart() throws {
        let store = try makeStore()
        store.finishOnboarding(city: jeddah, reasons: [.fajr, .jamaah])

        #expect(store.isOnboarded)
        #expect(store.city == jeddah)
        let restarted = try makeStore()
        #expect(restarted.isOnboarded)
        #expect(restarted.city == jeddah)
        #expect(OnboardingSettings(defaults: defaults).reasons == [.fajr, .jamaah])
    }
}
