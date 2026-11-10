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

/// The saved form: `{"version": 1, "days": {"2026-11-10": {"fajr": {...}}}}`.
/// Days and prayers are named in plain text so the file stays readable.
extension PrayerLog: Codable {
    static let formatVersion = 1

    private enum CodingKeys: String, CodingKey {
        case version, days
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .version)
        guard version == Self.formatVersion else {
            throw DecodingError.dataCorruptedError(
                forKey: .version, in: container, debugDescription: "Unsupported prayer log version \(version)")
        }
        let saved = try container.decode([String: [String: PrayerEntry]].self, forKey: .days)
        for (dayText, entries) in saved {
            guard let key = DayKey(dayText) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .days, in: container, debugDescription: "Not a yyyy-MM-dd date: \(dayText)")
            }
            for (name, entry) in entries {
                guard let prayer = Prayer.allCases.first(where: { "\($0)" == name }) else {
                    throw DecodingError.dataCorruptedError(
                        forKey: .days, in: container, debugDescription: "Unknown prayer: \(name)")
                }
                days[key, default: [:]][prayer] = entry
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.formatVersion, forKey: .version)
        var saved: [String: [String: PrayerEntry]] = [:]
        for (key, entries) in days {
            saved[key.description] = Dictionary(uniqueKeysWithValues: entries.map { ("\($0.key)", $0.value) })
        }
        try container.encode(saved, forKey: .days)
    }
}
