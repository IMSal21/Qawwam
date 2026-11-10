import Foundation

/// Names one prayer day by the Gregorian date it starts on, e.g. 2026-11-10.
public struct DayKey: Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public init(_ prayerDay: PrayerDay) {
        self.init(year: prayerDay.date.year!, month: prayerDay.date.month!, day: prayerDay.date.day!)
    }

    /// Reads a `yyyy-MM-dd` date. Returns nil for anything else, including dates that don't exist.
    public init?(_ text: String) {
        let parts = text.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
            let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]),
            Self.isRealDate(year: year, month: month, day: day)
        else { return nil }
        self.init(year: year, month: month, day: day)
    }

    public var description: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    public static func < (lhs: DayKey, rhs: DayKey) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        guard let key = DayKey(text) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not a yyyy-MM-dd date: \(text)")
        }
        self = key
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    private static func isRealDate(year: Int, month: Int, day: Int) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = DateComponents(year: year, month: month, day: day)
        guard let date = calendar.date(from: components) else { return false }
        let back = calendar.dateComponents([.year, .month, .day], from: date)
        return back.year == year && back.month == month && back.day == day
    }
}

/// One logged prayer.
public struct PrayerEntry: Codable, Equatable, Sendable {
    public var timing: PrayerTiming
    public let loggedAt: Date
    public var inCongregation: Bool

    public init(timing: PrayerTiming, loggedAt: Date, inCongregation: Bool) {
        self.timing = timing
        self.loggedAt = loggedAt
        self.inCongregation = inCongregation
    }
}

/// Where a prayer stands at a given moment.
public enum PrayerStatus: Equatable, Sendable {
    case upcoming
    case due
    case prayed(PrayerTiming)
    case missed
}

public enum PrayerLogError: Error, Equatable {
    /// The prayer's time hasn't started yet.
    case notYetDue
    /// The next Fajr has begun, so the day can no longer change.
    case dayClosed
    /// The prayer isn't logged, so there is nothing to change.
    case notLogged
}
