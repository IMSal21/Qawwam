import Foundation

/// Why the person came to Qawwam, from the first onboarding step. Saved for reminders and challenges later.
public enum OnboardingReason: String, CaseIterable, Sendable {
    case onTime, keepFive, fajr, jamaah, progress
}

/// What onboarding saves, read and written through the App Group's UserDefaults.
public struct OnboardingSettings: Equatable, Sendable {
    static let doneKey = "onboardingDone"
    static let cityKey = "cityID"
    static let reasonsKey = "onboardingReasons"

    public var isDone: Bool
    public var city: City?
    public var reasons: Set<OnboardingReason>

    public init(isDone: Bool = false, city: City? = nil, reasons: Set<OnboardingReason> = []) {
        self.isDone = isDone
        self.city = city
        self.reasons = reasons
    }

    /// Loads the saved settings. A city id that isn't on the list reads as no city.
    public init(defaults: UserDefaults) {
        isDone = defaults.bool(forKey: Self.doneKey)
        city = defaults.string(forKey: Self.cityKey).flatMap(SaudiCities.city(id:))
        let saved = defaults.stringArray(forKey: Self.reasonsKey) ?? []
        reasons = Set(saved.compactMap(OnboardingReason.init(rawValue:)))
    }

    public func save(to defaults: UserDefaults) {
        defaults.set(isDone, forKey: Self.doneKey)
        if let city {
            defaults.set(city.id, forKey: Self.cityKey)
        } else {
            defaults.removeObject(forKey: Self.cityKey)
        }
        defaults.set(OnboardingReason.allCases.filter(reasons.contains).map(\.rawValue), forKey: Self.reasonsKey)
    }
}
