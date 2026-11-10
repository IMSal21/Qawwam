import Adhan
import Foundation

public enum PrayerTimesError: Error, Equatable {
    /// Adhan could not compute every time for this date and place.
    case unavailable(DateComponents)
}

/// Computes Umm al-Qura prayer times with Adhan.
public struct PrayerTimesCalculator: Sendable {
    /// Isha follows Maghrib by 90 minutes in Umm al-Qura, and by 120 minutes in Ramadan.
    static let ramadanIshaInterval = 120

    public let settings: PrayerSettings

    public init(settings: PrayerSettings) {
        self.settings = settings
    }

    /// The prayer day starting on `date` (year, month, day) at `point`, using `timeZone` to tell
    /// which Hijri month the date falls in.
    public func day(_ date: DateComponents, at point: GeoPoint, in timeZone: TimeZone) throws -> PrayerDay {
        let today = try adhanTimes(date, at: point, in: timeZone)
        let tomorrow = try adhanTimes(Self.dayAfter(date), at: point, in: timeZone)

        return PrayerDay(
            date: DateComponents(year: date.year, month: date.month, day: date.day),
            times: [
                .fajr: Self.roundedUp(today.fajr), .dhuhr: Self.roundedUp(today.dhuhr),
                .asr: Self.roundedUp(today.asr), .maghrib: Self.roundedUp(today.maghrib),
                .isha: Self.roundedUp(today.isha),
            ],
            sunrise: Self.roundedDown(today.sunrise),
            nextFajr: Self.roundedUp(tomorrow.fajr)
        )
    }

    /// The prayer day `instant` falls in. Before Fajr, that is the previous day's.
    public func prayerDay(containing instant: Date, at point: GeoPoint, in timeZone: TimeZone) throws -> PrayerDay {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = try day(calendar.dateComponents([.year, .month, .day], from: instant), at: point, in: timeZone)
        guard instant < today.time(of: .fajr) else { return today }

        let yesterday = calendar.date(byAdding: .day, value: -1, to: instant)!
        return try day(calendar.dateComponents([.year, .month, .day], from: yesterday), at: point, in: timeZone)
    }

    private func adhanTimes(_ date: DateComponents, at point: GeoPoint, in timeZone: TimeZone) throws -> PrayerTimes {
        let coordinates = Coordinates(latitude: point.latitude, longitude: point.longitude)
        var params = CalculationMethod.ummAlQura.params
        params.madhab = settings.madhab == .hanafi ? .hanafi : .shafi
        params.highLatitudeRule = .recommended(for: coordinates)
        params.rounding = .none
        params.adjustments = PrayerAdjustments(
            fajr: settings.adjustment(for: .fajr),
            dhuhr: settings.adjustment(for: .dhuhr),
            asr: settings.adjustment(for: .asr),
            maghrib: settings.adjustment(for: .maghrib),
            isha: settings.adjustment(for: .isha)
        )
        if Self.isRamadan(date, in: timeZone) {
            params.ishaInterval = Self.ramadanIshaInterval
        }

        guard let times = PrayerTimes(coordinates: coordinates, date: date, calculationParameters: params) else {
            throw PrayerTimesError.unavailable(date)
        }
        return times
    }

    /// The official Umm al-Qura timetable rounds on the side of caution: a prayer's start up to the
    /// next minute, and sunrise (the end of Fajr) down. Matching it keeps us within a minute of it.
    static func roundedUp(_ date: Date) -> Date {
        Date(timeIntervalSince1970: (date.timeIntervalSince1970 / 60).rounded(.up) * 60)
    }

    static func roundedDown(_ date: Date) -> Date {
        Date(timeIntervalSince1970: (date.timeIntervalSince1970 / 60).rounded(.down) * 60)
    }

    static func isRamadan(_ date: DateComponents, in timeZone: TimeZone) -> Bool {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = timeZone
        var noon = date
        noon.hour = 12
        guard let instant = gregorian.date(from: noon) else { return false }

        var hijri = Calendar(identifier: .islamicUmmAlQura)
        hijri.timeZone = timeZone
        return hijri.component(.month, from: instant) == 9
    }

    private static func dayAfter(_ date: DateComponents) -> DateComponents {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let next = utc.date(byAdding: .day, value: 1, to: utc.date(from: date)!)!
        return utc.dateComponents([.year, .month, .day], from: next)
    }
}
