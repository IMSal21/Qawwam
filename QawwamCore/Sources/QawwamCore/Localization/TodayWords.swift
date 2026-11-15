/// Words for the today screen.
extension Words {
    // MARK: Tabs and titles

    public var today: String { pick("اليوم", "Today") }
    public var farm: String { pick("المزرعة", "Farm") }
    public var profile: String { pick("ملفي", "Profile") }
    public var comingSoon: String { pick("قريبًا", "Coming soon") }
    public var riyadh: String { pick("الرياض", "Riyadh") }

    // MARK: Summary card

    public var ofFivePrayers: String { pick("من 5 صلوات", "of 5 prayers") }

    /// The ring's spoken label: "صُلّيت 2 من 5 صلوات اليوم".
    public func prayedOutOfFive(_ count: Int) -> String {
        pick("صُلّيت \(number(count)) من 5 صلوات اليوم", "\(number(count)) of 5 prayers prayed today")
    }

    /// "+15 نقطة اليوم" / "+15 points today".
    public func pointsToday(_ count: Int) -> String {
        switch language {
        case .arabic:
            let noun = ArabicPlural(count) == .few ? "نقاط" : "نقطة"
            return "+\(number(count)) \(noun) اليوم"
        case .english:
            return "+\(number(count)) \(count == 1 ? "point" : "points") today"
        }
    }

    public func timeFor(_ prayerName: String) -> String {
        pick("حان وقت \(prayerName)", "Time for \(prayerName)")
    }

    public func next(_ prayerName: String) -> String {
        pick("التالي: \(prayerName)", "Next: \(prayerName)")
    }

    /// "باقي ساعة و49 دقيقة قبل المغرب".
    public func remaining(minutes: Int, before prayerName: String) -> String {
        pick(
            "باقي \(duration(minutes: minutes)) قبل \(prayerName)",
            "\(duration(minutes: minutes)) left before \(prayerName)")
    }

    /// "يبدأ 5:09 م · بعد ساعة و49 دقيقة".
    public func starts(at time: String, in minutes: Int) -> String {
        pick("يبدأ \(time) · بعد \(duration(minutes: minutes))", "Starts \(time) · in \(duration(minutes: minutes))")
    }

    public var allPrayedToday: String { pick("أتممت صلوات اليوم", "All of today's prayers are done") }

    // MARK: Prayer rows

    public func due(until time: String) -> String {
        pick("حان وقتها · حتى \(time)", "Time to pray · until \(time)")
    }

    public func starts(at time: String) -> String {
        pick("يبدأ \(time)", "Starts \(time)")
    }

    public var notLoggedCountsLate: String { pick("لم تُسجَّل · تُحسب متأخرة", "Not logged · counts as late") }
    public var prayed: String { pick("صلّيت", "Prayed") }
    public var undo: String { pick("تراجع", "Undo") }

    public func undoLabel(_ prayerName: String) -> String {
        pick("تراجع عن تسجيل \(prayerName)", "Undo \(prayerName)")
    }

    public var inCongregation: String { pick("في جماعة", "In congregation") }
    public var addCongregation: String { pick("أضف جماعة", "Add congregation") }
    public var prayedItOnTime: String { pick("صلّيتها في وقتها", "I prayed it on time") }
    public var markLate: String { pick("أعدها متأخرة", "Mark as late") }

    // MARK: Durations

    /// "ساعة و49 دقيقة" / "1 hr 49 min". Rounds down to whole minutes.
    public func duration(minutes total: Int) -> String {
        let hours = max(total, 0) / 60
        let minutes = max(total, 0) % 60
        switch language {
        case .arabic:
            if hours == 0 && minutes == 0 { return "أقل من دقيقة" }
            if hours == 0 { return ArabicCountedNoun.minute.counted(minutes, digits: number(minutes)) }
            let hourText = ArabicCountedNoun.hour.counted(hours, digits: number(hours))
            if minutes == 0 { return hourText }
            let minuteText =
                minutes == 1 ? "دقيقة" : ArabicCountedNoun.minute.counted(minutes, digits: number(minutes))
            return "\(hourText) و\(minuteText)"
        case .english:
            if hours == 0 && minutes == 0 { return "less than a minute" }
            if hours == 0 { return "\(number(minutes)) min" }
            if minutes == 0 { return "\(number(hours)) hr" }
            return "\(number(hours)) hr \(number(minutes)) min"
        }
    }
}

extension ArabicCountedNoun {
    static let minute = ArabicCountedNoun(
        singular: "دقيقة", one: "دقيقة واحدة", two: "دقيقتان", plural: "دقائق", accusative: "دقيقة")
    static let hour = ArabicCountedNoun(
        singular: "ساعة", one: "ساعة", two: "ساعتان", plural: "ساعات", accusative: "ساعة")
}
