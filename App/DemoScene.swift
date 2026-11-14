import Foundation
import QawwamCore

/// Seeded logs for UI tests and screenshots. Written to a temporary folder, never the real log.
@MainActor
enum DemoScene {
    /// The mockup's scene: 12 complete days, then today with Fajr on time in congregation and Dhuhr late.
    static func mockup(now: Date) -> (PrayerLogStore, UserDefaults) {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("qawwam-demo-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let store = FilePrayerLogStore(fileURL: folder.appendingPathComponent("prayer-log.json"))
        let defaults = UserDefaults(suiteName: "qawwam-demo-\(UUID().uuidString)")!

        let calculator = PrayerTimesCalculator(settings: .ummAlQura)
        guard let today = try? calculator.prayerDay(containing: now, at: TodayStore.riyadh, in: TodayStore.saudi)
        else { return (store, defaults) }
        let first = DayKey(today).adding(days: -12)
        defaults.set(first.description, forKey: "firstDay")

        var log = PrayerLog()
        var key = first
        while key < DayKey(today) {
            let components = DateComponents(year: key.year, month: key.month, day: key.day)
            if let day = try? calculator.day(components, at: TodayStore.riyadh, in: TodayStore.saudi) {
                for prayer in Prayer.allCases {
                    try? log.markPrayed(prayer, in: day, at: day.time(of: prayer).addingTimeInterval(300))
                }
            }
            key = key.adding(days: 1)
        }
        try? log.markPrayed(
            .fajr, in: today, at: today.time(of: .fajr).addingTimeInterval(600), inCongregation: true)
        try? log.markPrayed(.dhuhr, in: today, at: today.time(of: .asr).addingTimeInterval(840))
        try? store.save(log)
        return (store, defaults)
    }
}
