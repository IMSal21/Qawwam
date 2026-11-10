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
                .fajr: today.fajr, .dhuhr: today.dhuhr, .asr: today.asr,
                .maghrib: today.maghrib, .isha: today.isha,
            ],
            sunrise: today.sunrise,
            nextFajr: tomorrow.fajr
        )
    }

    private func adhanTimes(_ date: DateComponents, at point: GeoPoint, in timeZone: TimeZone) throws -> PrayerTimes {
        let coordinates = Coordinates(latitude: point.latitude, longitude: point.longitude)
        var params = CalculationMethod.ummAlQura.params
        params.madhab = settings.madhab == .hanafi ? .hanafi : .shafi
        params.highLatitudeRule = .recommended(for: coordinates)
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
