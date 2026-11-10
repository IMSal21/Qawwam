/// The languages the app speaks. Arabic is the default.
public enum AppLanguage: String, CaseIterable, Sendable {
    case arabic = "ar"
    case english = "en"
}

/// The app's words and formats in one language. Pure values, no UI.
public struct Words: Sendable {
    public let language: AppLanguage

    public init(_ language: AppLanguage) {
        self.language = language
    }

    /// The prayer's name. Dhuhr is Jumu'ah on Fridays, at the same time.
    public func name(of prayer: Prayer, on day: DayKey) -> String {
        if prayer == .dhuhr && day.weekdayIndex == 5 {
            return pick("الجمعة", "Jumu'ah")
        }
        switch prayer {
        case .fajr: return pick("الفجر", "Fajr")
        case .dhuhr: return pick("الظهر", "Dhuhr")
        case .asr: return pick("العصر", "Asr")
        case .maghrib: return pick("المغرب", "Maghrib")
        case .isha: return pick("العشاء", "Isha")
        }
    }

    public var sunrise: String { pick("الشروق", "Sunrise") }

    public func status(_ status: PrayerStatus) -> String {
        switch status {
        case .upcoming: pick("قادمة", "Upcoming")
        case .due: pick("حان وقتها", "Time to pray")
        case .prayed(.onTime): pick("في وقتها", "On time")
        case .prayed(.late): pick("متأخرة", "Late")
        case .missed: pick("فائتة", "Missed")
        }
    }

    func pick(_ arabic: String, _ english: String) -> String {
        language == .arabic ? arabic : english
    }
}
