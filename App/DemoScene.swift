import Foundation
import QawwamCore

/// Seeded logs for UI tests and screenshots. Written to a temporary folder, never the real log.
@MainActor
enum DemoScene {
    /// The mockups' scene: the month of Jumada al-Ula 1448 up to today, its 30th day. The user started on
    /// day 4. Day 17 has Maghrib and Isha missed, the listed days are all on time, and the others have one
    /// prayer late. That leaves a streak of 12. Today Fajr is on time in congregation and Dhuhr is late.
    static let fruitDays: Set = [4, 6, 7, 9, 11, 12, 14, 16, 19, 20, 22, 24, 26, 28, 29]

    static func mockup(now: Date) -> (PrayerLogStore, UserDefaults) {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("qawwam-demo-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let store = FilePrayerLogStore(fileURL: folder.appendingPathComponent("prayer-log.json"))
        let defaults = UserDefaults(suiteName: "qawwam-demo-\(UUID().uuidString)")!
        OnboardingSettings(isDone: true, city: SaudiCities.riyadh).save(to: defaults)

        let calculator = PrayerTimesCalculator(settings: .ummAlQura)
        guard let today = try? calculator.prayerDay(containing: now, at: SaudiCities.riyadh.location, in: TodayStore.saudi)
        else { return (store, defaults) }
        let first = DayKey(today).adding(days: -26)
        defaults.set(first.description, forKey: "firstDay")

        var log = PrayerLog()
        var key = first
        var hijriDay = 4
        while key < DayKey(today) {
            let components = DateComponents(year: key.year, month: key.month, day: key.day)
            if let day = try? calculator.day(components, at: SaudiCities.riyadh.location, in: TodayStore.saudi) {
                for (index, prayer) in Prayer.allCases.enumerated() {
                    if hijriDay == 17 && index >= 3 { continue }
                    let late = !fruitDays.contains(hijriDay) && hijriDay != 17 && index == hijriDay % 5
                    let time =
                        late
                        ? day.window(for: prayer).end.addingTimeInterval(600)
                        : day.time(of: prayer).addingTimeInterval(300)
                    try? log.markPrayed(prayer, in: day, at: time)
                }
            }
            key = key.adding(days: 1)
            hijriDay += 1
        }
        try? log.markPrayed(
            .fajr, in: today, at: today.time(of: .fajr).addingTimeInterval(600), inCongregation: true)
        try? log.markPrayed(.dhuhr, in: today, at: today.time(of: .asr).addingTimeInterval(840))
        try? store.save(log)
        return (store, defaults)
    }

    /// A fresh install for the onboarding UI tests. It keeps its log and settings between launches so a
    /// relaunch can be tested; `reset` clears them first.
    static func fresh(reset: Bool) -> (PrayerLogStore, UserDefaults) {
        let name = "qawwam-fresh"
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        let defaults = UserDefaults(suiteName: name)!
        if reset {
            try? FileManager.default.removeItem(at: folder)
            defaults.removePersistentDomain(forName: name)
        }
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return (FilePrayerLogStore(fileURL: folder.appendingPathComponent("prayer-log.json")), defaults)
    }
}
