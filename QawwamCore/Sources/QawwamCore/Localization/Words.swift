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

    /// Western digits in both languages, with thousands grouped by commas.
    public func number(_ value: Int) -> String {
        let digits = String(value.magnitude)
        var grouped = ""
        for (index, digit) in digits.enumerated() {
            if index > 0 && (digits.count - index) % 3 == 0 { grouped.append(",") }
            grouped.append(digit)
        }
        return value < 0 ? "-" + grouped : grouped
    }

    public func days(_ count: Int) -> String {
        switch language {
        case .arabic: ArabicCountedNoun.day.counted(count, digits: number(count))
        case .english: "\(number(count)) \(count == 1 ? "day" : "days")"
        }
    }

    public func points(_ count: Int) -> String {
        switch language {
        case .arabic: ArabicCountedNoun.point.counted(count, digits: number(count))
        case .english: "\(number(count)) \(count == 1 ? "point" : "points")"
        }
    }

    public func level(_ level: Int) -> String {
        pick("المستوى \(number(level))", "Level \(number(level))")
    }

    /// The main date: "12 رجب 1447 هـ" / "12 Rajab 1447 AH".
    public func hijri(_ date: HijriDate) -> String {
        let month = pick(Self.arabicHijriMonths[date.month - 1], Self.englishHijriMonths[date.month - 1])
        return pick(
            "\(number(date.day)) \(month) \(date.year) هـ", "\(number(date.day)) \(month) \(date.year) AH")
    }

    /// The reference date: "1 يناير 2026م" / "1 January 2026".
    public func gregorian(_ day: DayKey) -> String {
        let month = pick(Self.arabicGregorianMonths[day.month - 1], Self.englishGregorianMonths[day.month - 1])
        return pick("\(number(day.day)) \(month) \(day.year)م", "\(number(day.day)) \(month) \(day.year)")
    }

    public func weekday(_ day: DayKey) -> String {
        pick(Self.arabicWeekdays[day.weekdayIndex], Self.englishWeekdays[day.weekdayIndex])
    }

    static let arabicHijriMonths = [
        "محرم", "صفر", "ربيع الأول", "ربيع الآخر", "جمادى الأولى", "جمادى الآخرة", "رجب", "شعبان", "رمضان",
        "شوال", "ذو القعدة", "ذو الحجة",
    ]
    static let englishHijriMonths = [
        "Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Akhir", "Jumada al-Ula", "Jumada al-Akhirah", "Rajab",
        "Sha'ban", "Ramadan", "Shawwal", "Dhu al-Qa'dah", "Dhu al-Hijjah",
    ]
    static let arabicGregorianMonths = [
        "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو", "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر",
        "ديسمبر",
    ]
    static let englishGregorianMonths = [
        "January", "February", "March", "April", "May", "June", "July", "August", "September", "October",
        "November", "December",
    ]
    static let arabicWeekdays = ["الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"]
    static let englishWeekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    func pick(_ arabic: String, _ english: String) -> String {
        language == .arabic ? arabic : english
    }
}
