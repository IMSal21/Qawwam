import Foundation

/// The prayer times for one prayer day, which runs from Fajr to the next day's Fajr.
public struct PrayerDay: Equatable, Sendable {
    /// The Gregorian day this prayer day starts on.
    public let date: DateComponents
    public let sunrise: Date
    public let nextFajr: Date
    private let times: [Prayer: Date]

    init(date: DateComponents, times: [Prayer: Date], sunrise: Date, nextFajr: Date) {
        precondition(Set(times.keys) == Set(Prayer.allCases), "A prayer day needs all five times")
        self.date = date
        self.times = times
        self.sunrise = sunrise
        self.nextFajr = nextFajr
    }

    public func time(of prayer: Prayer) -> Date {
        times[prayer]!
    }
}
