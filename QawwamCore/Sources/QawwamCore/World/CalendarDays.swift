import Foundation

extension DayKey {
    private static let gregorian: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// Noon UTC on this day, a safe instant for calendar maths.
    var noon: Date {
        Self.gregorian.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    init(noon date: Date) {
        let parts = Self.gregorian.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year!, month: parts.month!, day: parts.day!)
    }

    func adding(days: Int) -> DayKey {
        DayKey(noon: Self.gregorian.date(byAdding: .day, value: days, to: noon)!)
    }

    /// 0 for Sunday up to 6 for Saturday.
    var weekdayIndex: Int {
        Self.gregorian.component(.weekday, from: noon) - 1
    }
}

extension HijriDate {
    static let ummAlQura: Calendar = {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// The Umm al-Qura date of a Gregorian day.
    public init(_ day: DayKey) {
        let parts = Self.ummAlQura.dateComponents([.year, .month, .day], from: day.noon)
        self.init(year: parts.year!, month: parts.month!, day: parts.day!)
    }
}
