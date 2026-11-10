import Foundation

/// Every logged prayer, by prayer day. A plain value: saving it is just encoding it.
public struct PrayerLog: Equatable, Sendable {
    private var days: [DayKey: [Prayer: PrayerEntry]] = [:]

    public init() {}

    public var isEmpty: Bool {
        days.isEmpty
    }
}
