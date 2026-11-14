import Foundation
import QawwamCore

/// What the today screen shows, worked out from the time passed in.
struct TodayModel: Equatable {
    struct Row: Equatable {
        let prayer: Prayer
        let name: String
        let time: String
    }

    static let riyadh = GeoPoint(latitude: 24.7136, longitude: 46.6753)
    static let saudi = TimeZone(identifier: "Asia/Riyadh")!

    let hijri: String
    let gregorian: String
    let weekday: String
    let rows: [Row]

    init(words: Words, now: Date) throws {
        let day = try PrayerTimesCalculator(settings: .ummAlQura)
            .prayerDay(containing: now, at: Self.riyadh, in: Self.saudi)
        let key = DayKey(day)
        hijri = words.hijri(HijriDate(key))
        gregorian = words.gregorian(key)
        weekday = words.weekday(key)
        rows = Prayer.allCases.map { prayer in
            Row(prayer: prayer, name: words.name(of: prayer, on: key), time: words.time(day.time(of: prayer)))
        }
    }
}
