import Foundation
import Observation
import QawwamCore

/// Holds the prayer log for the today screen: loads it, saves every change, and re-reads the clock.
@MainActor
@Observable
final class TodayStore {
    static let riyadh = GeoPoint(latitude: 24.7136, longitude: 46.6753)
    static let saudi = TimeZone(identifier: "Asia/Riyadh")!
    static let appGroup = "group.com.qawwam.app"
    private static let firstDayKey = "firstDay"

    private let store: PrayerLogStore
    private let clock: @MainActor () -> Date
    private let calculator = PrayerTimesCalculator(settings: .ummAlQura)
    let words: Words
    let firstDay: DayKey
    private(set) var log: PrayerLog
    private(set) var now: Date

    init(
        store: PrayerLogStore, defaults: UserDefaults, words: Words,
        clock: @escaping @MainActor () -> Date = { Date() }
    ) {
        self.store = store
        self.clock = clock
        self.words = words
        let now = clock()
        self.now = now
        self.log = (try? store.load()) ?? PrayerLog()
        let today = (try? calculator.prayerDay(containing: now, at: Self.riyadh, in: Self.saudi)).map(DayKey.init)
        if let saved = defaults.string(forKey: Self.firstDayKey).flatMap(DayKey.init) {
            firstDay = saved
        } else {
            firstDay = today ?? DayKey(year: 2026, month: 1, day: 1)
            defaults.set(firstDay.description, forKey: Self.firstDayKey)
        }
    }

    /// Prayer days from the first day up to the one containing now.
    var days: [PrayerDay] {
        guard let today = try? calculator.prayerDay(containing: now, at: Self.riyadh, in: Self.saudi) else { return [] }
        var result: [PrayerDay] = []
        var key = min(firstDay, DayKey(today))
        while key < DayKey(today) {
            let components = DateComponents(year: key.year, month: key.month, day: key.day)
            if let day = try? calculator.day(components, at: Self.riyadh, in: Self.saudi) { result.append(day) }
            key = key.adding(days: 1)
        }
        result.append(today)
        return result
    }

    var state: TodayState {
        TodayState(log: log, days: days, words: words, city: words.riyadh, now: now)
    }

    /// The farm screen for the current month, with `selected` (or today) on the day card.
    func farmState(selected: DayKey?) -> FarmScreenState {
        FarmScreenState(log: log, days: days, words: words, now: now, selected: selected)
    }

    func refresh() {
        now = clock()
    }

    func markPrayed(_ prayer: Prayer, inCongregation: Bool) {
        change { log, day, now in try log.markPrayed(prayer, in: day, at: now, inCongregation: inCongregation) }
    }

    func undo(_ prayer: Prayer) {
        change { log, day, now in try log.unmark(prayer, in: day, at: now) }
    }

    func setTiming(_ timing: PrayerTiming, for prayer: Prayer) {
        change { log, day, now in try log.setTiming(timing, for: prayer, in: day, at: now) }
    }

    func toggleCongregation(for prayer: Prayer) {
        change { log, day, now in
            let on = log.entry(for: prayer, in: day)?.inCongregation ?? false
            try log.setCongregation(!on, for: prayer, in: day, at: now)
        }
    }

    private func change(_ edit: (inout PrayerLog, PrayerDay, Date) throws -> Void) {
        refresh()
        guard let day = days.last else { return }
        var updated = log
        do {
            try edit(&updated, day, now)
            try store.save(updated)
            log = updated
        } catch {
            // The log stays as it was; nothing half-saved.
        }
    }
}
