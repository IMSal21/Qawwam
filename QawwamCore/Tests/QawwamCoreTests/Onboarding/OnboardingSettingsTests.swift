import Foundation
import Testing

@testable import QawwamCore

@Suite struct OnboardingSettingsTests {
    static func freshDefaults() -> UserDefaults {
        let name = "onboarding-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func aFreshInstallIsNotDone() {
        let settings = OnboardingSettings(defaults: Self.freshDefaults())
        #expect(settings == OnboardingSettings())
        #expect(!settings.isDone)
        #expect(settings.city == nil)
        #expect(settings.reasons.isEmpty)
    }

    @Test func savesAndLoads() {
        let defaults = Self.freshDefaults()
        let saved = OnboardingSettings(isDone: true, city: SaudiCities.city(id: "jeddah"), reasons: [.fajr, .progress])
        saved.save(to: defaults)
        #expect(OnboardingSettings(defaults: defaults) == saved)
    }

    @Test func anUnknownCityReadsAsNotChosen() {
        let defaults = Self.freshDefaults()
        defaults.set("atlantis", forKey: OnboardingSettings.cityKey)
        defaults.set(["fajr", "dancing"], forKey: OnboardingSettings.reasonsKey)
        let settings = OnboardingSettings(defaults: defaults)
        #expect(settings.city == nil)
        #expect(settings.reasons == [.fajr])
    }
}
