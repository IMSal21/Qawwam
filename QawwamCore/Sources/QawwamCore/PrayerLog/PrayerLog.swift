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

    /// Logs `prayer` as prayed. On time or late is decided from `now` and the prayer's window.
    /// Logging a prayer that is already logged changes nothing, so a second tap can't move the log time.
    public mutating func markPrayed(
        _ prayer: Prayer, in day: PrayerDay, at now: Date, inCongregation: Bool = false
    ) throws {
        try requireOpen(day, at: now)
        guard now >= day.time(of: prayer) else { throw PrayerLogError.notYetDue }
        guard entry(for: prayer, in: day) == nil else { return }
        let timing = day.timing(of: prayer, loggedAt: now)
        days[DayKey(day), default: [:]][prayer] = PrayerEntry(
            timing: timing, loggedAt: now, inCongregation: inCongregation)
    }

    /// Switches a logged prayer between on time and late, for when the user prayed in time but logged it later.
    public mutating func setTiming(_ timing: PrayerTiming, for prayer: Prayer, in day: PrayerDay, at now: Date) throws {
        try requireOpen(day, at: now)
        guard entry(for: prayer, in: day) != nil else { throw PrayerLogError.notLogged }
        days[DayKey(day)]?[prayer]?.timing = timing
    }

    /// Removes a logged prayer, so it is due again.
    public mutating func unmark(_ prayer: Prayer, in day: PrayerDay, at now: Date) throws {
        try requireOpen(day, at: now)
        let key = DayKey(day)
        guard days[key]?.removeValue(forKey: prayer) != nil else { throw PrayerLogError.notLogged }
        if days[key]?.isEmpty == true {
            days[key] = nil
        }
    }

    private func requireOpen(_ day: PrayerDay, at now: Date) throws {
        guard now < day.nextFajr else { throw PrayerLogError.dayClosed }
    }
}
