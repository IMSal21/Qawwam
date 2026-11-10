import Foundation

/// Every logged prayer, by prayer day. A plain value: saving it is just encoding it.
public struct PrayerLog: Equatable, Sendable {
    private var days: [DayKey: [Prayer: PrayerEntry]] = [:]

    public init() {}

    public var isEmpty: Bool {
        days.isEmpty
    }

    /// Where `prayer` stands at `now`. Missed is worked out from the time, never stored.
    public func status(of prayer: Prayer, in day: PrayerDay, at now: Date) -> PrayerStatus {
        if let entry = entry(for: prayer, in: day) {
            return .prayed(entry.timing)
        }
        if now >= day.nextFajr {
            return .missed
        }
        return now >= day.time(of: prayer) ? .due : .upcoming
    }

    public func entry(for prayer: Prayer, in day: PrayerDay) -> PrayerEntry? {
        days[DayKey(day)]?[prayer]
    }
}
