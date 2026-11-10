import Adhan
import Foundation

/// Namespace for the Qawwam core logic shared by the app and its widgets.
public enum QawwamCore {
    /// Confirms the Adhan dependency links and can compute a day's times.
    static func adhanIsAvailable() -> Bool {
        let date = DateComponents(year: 2026, month: 1, day: 1)
        let riyadh = Coordinates(latitude: 24.7136, longitude: 46.6753)
        let params = CalculationMethod.ummAlQura.params
        return PrayerTimes(coordinates: riyadh, date: date, calculationParameters: params) != nil
    }
}
